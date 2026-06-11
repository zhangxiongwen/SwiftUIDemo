//
//  CombineIntroTutorialView.swift
//  SwiftUIDemo
//
//  Combine 入门：Publisher / Subscriber / Subscription / Operator 核心概念。
//

import Combine
import SwiftUI

// MARK: - ViewModel（含详细注释的演示代码）

@MainActor
final class CombineIntroViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    private var cancellables = Set<AnyCancellable>()

    /// 演示 1：最基础的 Publisher → Subscriber 链路
    func runBasicPipeline() {
        resetLogs()
        appendLog("开始演示：Just(\"Hello Combine\")")

        // Just：立刻发出一个值，然后结束（完成）
        // 它是最简单的 Publisher，适合传递单个固定值
        let publisher = Just("Hello Combine")

        // sink：最常用的订阅方式
        // receiveValue：每收到一个值时执行
        // receiveCompletion：流结束时执行（正常完成或失败）
        publisher
            .sink { [weak self] completion in
                // completion 是 Subscribers.Completion<Never>
                // Never 表示这个 Publisher 不会失败
                switch completion {
                case .finished:
                    self?.appendLog("✅ 流正常结束 (.finished)")
                case .failure:
                    break // Just 不会走到这里
                }
            } receiveValue: { [weak self] value in
                self?.appendLog("📥 收到值: \"\(value)\"")
            }
            .store(in: &cancellables) // 必须保存，否则订阅会立刻被取消

        appendLog("订阅已建立，等待 Publisher 发出数据…")
    }

    /// 演示 2：操作符（Operator）如何变换数据流
    func runOperatorPipeline() {
        resetLogs()
        appendLog("开始演示：map 操作符")

        // 数据流：1 → 2 → 3，经过 map 后变成 "第1个" → "第2个" → "第3个"
        let numbers = [1, 2, 3].publisher

        numbers
            .map { number in
                // map 类似数组的 map：把每个上游值变换成新值
                "第\(number)个"
            }
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ 全部值处理完毕")
                }
            } receiveValue: { [weak self] text in
                self?.appendLog("📥 map 后: \(text)")
            }
            .store(in: &cancellables)
    }

    /// 演示 3：Cancellable — 取消订阅
    func runCancellableDemo() {
        resetLogs()
        appendLog("开始演示：手动取消订阅")

        // Timer.publish 会按间隔持续发出日期
        // 我们用 handleEvents 观察订阅生命周期
        let timer = Timer.publish(every: 0.5, on: .main, in: .common)
            .autoconnect() // 把 ConnectablePublisher 自动连接

        let cancellable = timer
            .prefix(5) // 只取前 5 个值
            .handleEvents(
                receiveSubscription: { [weak self] _ in
                    self?.appendLog("🔗 订阅已建立 (receiveSubscription)")
                },
                receiveCancel: { [weak self] in
                    self?.appendLog("🛑 订阅已取消 (receiveCancel)")
                }
            )
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ prefix(5) 取够 5 个值，流结束")
                }
            } receiveValue: { [weak self] date in
                self?.appendLog("⏱ 定时器: \(date.formatted(date: .omitted, time: .standard))")
            }

        // 也可以手动取消：cancellable.cancel()
        // 这里我们存入 Set，页面销毁时自动取消
        cancellable.store(in: &cancellables)
        appendLog("提示：离开页面时 cancellable 自动释放，订阅随之取消")
    }
}

// MARK: - View

struct CombineIntroTutorialView: View {
    @StateObject private var viewModel = CombineIntroViewModel()

    var body: some View {
        CombineTutorialPage(title: "核心概念") {
            TutorialConceptCard(
                title: "Combine 是什么？",
                content: """
                Combine 是 Apple 在 iOS 13 引入的响应式框架，用来处理「随时间变化的数据流」。
                网络请求、用户输入、定时器、通知……都可以抽象成 Publisher（发布者），
                经过 Operator（操作符）变换后，由 Subscriber（订阅者）消费。
                """
            )

            TutorialConceptCard(
                title: "四个核心角色",
                content: """
                ① Publisher：发出值的源头（如 Just、URLSession.DataTaskPublisher）
                ② Subscriber：接收值的终端（如 sink、assign）
                ③ Subscription：连接发布者和订阅者的「合同」，可 cancel()
                ④ Operator：中间处理站（map、filter、debounce 等）
                """
            )

            TutorialCodeBlock(
                title: "最小可运行示例",
                code: """
                import Combine

                // 1. 创建 Publisher
                let publisher = Just("Hello")

                // 2. 订阅（Subscriber）
                let cancellable = publisher
                    .map { $0 + " Combine!" }  // 3. Operator
                    .sink { value in
                        print(value)  // Hello Combine!
                    }

                // 4. 保存 cancellable，否则订阅立即失效
                """
            )

            demoSection(
                title: "演示 1 · Publisher → Subscriber",
                code: "Just(\"Hello Combine\").sink { … }",
                action: viewModel.runBasicPipeline
            )

            demoSection(
                title: "演示 2 · Operator 变换",
                code: "[1,2,3].publisher.map { \"第\\($0)个\" }",
                action: viewModel.runOperatorPipeline
            )

            demoSection(
                title: "演示 3 · 订阅生命周期",
                code: "Timer.publish(…).prefix(5).handleEvents(…)",
                action: viewModel.runCancellableDemo
            )

            TutorialConceptCard(
                title: "新手必记",
                content: """
                • 一定要把 AnyCancellable 存到 Set 或属性里，否则订阅瞬间被取消
                • UI 更新必须在主线程，用 .receive(on: DispatchQueue.main)
                • Publisher 是「冷」的：有订阅者才开始工作（Subject 和部分操作符例外）
                • 一个 Publisher 可以被多个 Subscriber 订阅（取决于是否 share/replay）
                """
            )
        }
    }

    private func demoSection(title: String, code: String, action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)

            TutorialCodeBlock(title: "关键代码", code: code)

            TutorialDemoActions(runTitle: "运行演示", onRun: action) {
                viewModel.resetLogs()
            }

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }
}
