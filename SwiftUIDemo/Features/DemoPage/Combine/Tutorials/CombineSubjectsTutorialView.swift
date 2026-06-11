//
//  CombineSubjectsTutorialView.swift
//  SwiftUIDemo
//
//  Subject：PassthroughSubject 与 CurrentValueSubject
//

import Combine
import SwiftUI

@MainActor
final class CombineSubjectsViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    @Published var passthroughInput = ""
    @Published var currentValueInput = ""
    @Published var currentValueDisplay = "（暂无）"
    private var cancellables = Set<AnyCancellable>()

    private let passthrough = PassthroughSubject<String, Never>()
    private let currentValue = CurrentValueSubject<Int, Never>(0)

    init() {
        // PassthroughSubject：订阅后只收到「订阅之后」发送的值
        passthrough
            .sink { [weak self] text in
                self?.appendLog("📡 Passthrough 收到: \"\(text)\"")
            }
            .store(in: &cancellables)

        // CurrentValueSubject：订阅时立刻收到「当前最新值」，之后持续更新
        currentValue
            .sink { [weak self] number in
                self?.currentValueDisplay = "\(number)"
                self?.appendLog("💾 CurrentValue 更新: \(number)")
            }
            .store(in: &cancellables)
    }

    func explainPassthrough() {
        resetLogs()
        appendLog("PassthroughSubject 像「广播站」：只转发订阅后的新事件")
        appendLog("已在 init 中建立订阅，现在发送 3 个值…")

        passthrough.send("第一条消息")
        passthrough.send("第二条消息")
        passthrough.send("第三条消息")
    }

    func sendPassthroughValue() {
        guard !passthroughInput.isEmpty else { return }
        passthrough.send(passthroughInput)
        passthroughInput = ""
    }

    func explainCurrentValue() {
        resetLogs()
        appendLog("CurrentValueSubject 像「带初始值的盒子」")
        appendLog("当前值: \(currentValue.value)")
        appendLog("发送 .send(10) 和 .send(20)…")

        currentValue.send(10)
        currentValue.send(20)
    }

    func sendCurrentValueDelta() {
        guard let delta = Int(currentValueInput) else { return }
        // 基于当前值累加
        currentValue.send(currentValue.value + delta)
        currentValueInput = ""
    }

    /// 演示：Subject 既是 Publisher 也是 Subscriber（可以 send 值）
    func demoSubjectAsBridge() {
        resetLogs()
        appendLog("实战：用 Subject 桥接非 Combine 的回调 API")

        // 模拟一个传统的 delegate / 闭包回调
        let callbackAPI = LegacyCounterService()

        // Subject 把回调事件转成 Publisher
        let bridge = PassthroughSubject<Int, Never>()

        callbackAPI.onTick = { count in
            bridge.send(count)
        }

        bridge
            .prefix(3)
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ 收到 3 次 tick，停止监听")
                }
            } receiveValue: { [weak self] count in
                self?.appendLog("🔔 回调桥接: tick = \(count)")
            }
            .store(in: &cancellables)

        callbackAPI.start()
        appendLog("LegacyCounterService 已启动（每 0.4 秒 tick 一次）")
    }
}

/// 模拟旧式回调 API（非 Combine）
private final class LegacyCounterService {
    var onTick: ((Int) -> Void)?
    private var count = 0
    private var timer: Timer?

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
            guard let self else { return }
            self.count += 1
            self.onTick?(self.count)
            if self.count >= 3 {
                self.timer?.invalidate()
            }
        }
    }
}

struct CombineSubjectsTutorialView: View {
    @StateObject private var viewModel = CombineSubjectsViewModel()

    var body: some View {
        CombineTutorialPage(title: "Subject 主题") {
            TutorialConceptCard(
                title: "Subject 是什么？",
                content: """
                Subject 是一种特殊的 Publisher，你可以手动 .send() 值进去。
                它常用于：把 Delegate / Target-Action / 闭包回调 桥接进 Combine 管道。
                """
            )

            TutorialConceptCard(
                title: "两种 Subject 对比",
                content: """
                PassthroughSubject：不保存状态，订阅者只收到订阅后的新值。
                CurrentValueSubject：保存最新值，新订阅者立刻收到当前值（类似 @Published 的底层）。
                """
            )

            TutorialCodeBlock(
                title: "PassthroughSubject",
                code: """
                let subject = PassthroughSubject<String, Never>()

                subject.sink { print($0) }.store(in: &bag)

                subject.send("A")  // 订阅者收到 "A"
                subject.send("B")  // 订阅者收到 "B"
                // 新订阅者不会收到 A、B（除非之后再有 send）
                """
            )

            TutorialDemoActions(runTitle: "运行 Passthrough 演示", onRun: viewModel.explainPassthrough)

            HStack {
                TextField("输入消息", text: $viewModel.passthroughInput)
                    .textFieldStyle(.roundedBorder)
                Button("发送") { viewModel.sendPassthroughValue() }
                    .buttonStyle(.borderedProminent)
            }

            Divider()

            TutorialCodeBlock(
                title: "CurrentValueSubject",
                code: """
                let score = CurrentValueSubject<Int, Never>(0)

                score.sink { print($0) }.store(in: &bag)
                // 立刻打印 0（当前值）

                score.send(5)   // 打印 5
                print(score.value)  // 直接读取：5
                """
            )

            HStack {
                Text("当前值:")
                Text(viewModel.currentValueDisplay)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(AppColors.primary)
            }

            TutorialDemoActions(runTitle: "运行 CurrentValue 演示", onRun: viewModel.explainCurrentValue)

            HStack {
                TextField("增减数值", text: $viewModel.currentValueInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numbersAndPunctuation)
                Button("累加") { viewModel.sendCurrentValueDelta() }
                    .buttonStyle(.borderedProminent)
            }

            Divider()

            TutorialCodeBlock(
                title: "桥接回调 API",
                code: """
                let bridge = PassthroughSubject<Int, Never>()
                legacyService.onTick = { bridge.send($0) }
                bridge.sink { print("tick:", $0) }
                """
            )

            TutorialDemoActions(runTitle: "运行桥接演示", onRun: viewModel.demoSubjectAsBridge)

            Button("清空日志") { viewModel.resetLogs() }
                .buttonStyle(.bordered)

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }
}
