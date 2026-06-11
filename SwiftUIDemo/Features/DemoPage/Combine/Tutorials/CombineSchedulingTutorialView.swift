//
//  CombineSchedulingTutorialView.swift
//  SwiftUIDemo
//
//  线程调度：subscribe(on:) 与 receive(on:)
//

import Combine
import SwiftUI

@MainActor
final class CombineSchedulingViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    @Published var uiResult = "（等待演示）"
    private var cancellables = Set<AnyCancellable>()

    func demoWithoutReceiveOn() {
        resetLogs()
        appendLog("❌ 错误示范：在后台线程直接更新 @Published")

        Just("后台数据")
            .subscribe(on: DispatchQueue.global()) // 在后台执行
            .sink { [weak self] value in
                // 此时在后台线程！直接改 @Published 可能崩溃或 UI 不刷新
                let thread = Thread.isMainThread ? "主线程" : "后台线程"
                self?.appendLog("⚠️ sink 运行在: \(thread)")
                self?.appendLog("📥 值: \(value)（未切回主线程）")
            }
            .store(in: &cancellables)
    }

    func demoWithReceiveOn() {
        resetLogs()
        appendLog("✅ 正确示范：receive(on: DispatchQueue.main)")

        Just("后台处理完毕的数据")
            .subscribe(on: DispatchQueue.global())  // 上游在后台
            .receive(on: DispatchQueue.main)        // 下游切到主线程
            .sink { [weak self] value in
                let thread = Thread.isMainThread ? "主线程 ✅" : "后台线程 ❌"
                self?.appendLog("sink 运行在: \(thread)")
                self?.uiResult = value
                self?.appendLog("📥 UI 已安全更新: \(value)")
            }
            .store(in: &cancellables)
    }

    func demoHeavyWorkPipeline() {
        resetLogs()
        appendLog("实战：模拟耗时计算 → 主线程展示")

        let input = (1...5).publisher

        input
            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
            .map { number -> String in
                // 模拟耗时操作（在后台线程执行）
                Thread.sleep(forTimeInterval: 0.3)
                return "计算结果: \(number * number)"
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ 全部计算完成")
                }
            } receiveValue: { [weak self] result in
                self?.appendLog("📥 \(result)")
            }
            .store(in: &cancellables)

        appendLog("⏳ 5 个数字依次在后台计算，主线程接收结果…")
    }
}

struct CombineSchedulingTutorialView: View {
    @StateObject private var viewModel = CombineSchedulingViewModel()

    var body: some View {
        CombineTutorialPage(title: "线程调度") {
            TutorialConceptCard(
                title: "两个关键操作符",
                content: """
                subscribe(on:)：指定「上游 Publisher 在哪个线程执行」。
                receive(on:)：指定「下游 Subscriber 在哪个线程接收」。
                SwiftUI 的 @Published 必须在主线程更新，所以 UI 相关管道末尾一定要 receive(on: .main)。
                """
            )

            TutorialCodeBlock(
                title: "标准网络请求模板",
                code: """
                URLSession.shared.dataTaskPublisher(for: url)
                    .subscribe(on: DispatchQueue.global())  // 网络在后台
                    .map { … }                              // 解析也在后台
                    .receive(on: DispatchQueue.main)        // UI 更新在主线程
                    .sink { … }
                    .store(in: &cancellables)
                """
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("UI 展示").font(.headline)
                Text(viewModel.uiResult)
                    .font(.title3.monospaced())
                    .foregroundStyle(AppColors.primary)
            }

            schedulingDemo("错误：不切主线程", viewModel.demoWithoutReceiveOn)
            schedulingDemo("正确：receive(on: .main)", viewModel.demoWithReceiveOn)
            schedulingDemo("耗时计算管道", viewModel.demoHeavyWorkPipeline)

            TutorialConceptCard(
                title: "记忆口诀",
                content: """
                「干活在后台，展示在主线程」
                subscribe(on:) 放前面（决定干活在哪）
                receive(on:) 放后面（决定结果去哪）
                """
            )

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }

    private func schedulingDemo(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button("运行 \(name)") { action() }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
