//
//  CombinePublishersTutorialView.swift
//  SwiftUIDemo
//
//  基础发布者：Just、Empty、Fail、Future、Deferred
//

import Combine
import SwiftUI

@MainActor
final class CombinePublishersViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    private var cancellables = Set<AnyCancellable>()

    /// Just：立即发出一个值并完成
    func demoJust() {
        resetLogs()
        appendLog("Just(\"Swift\") → 立刻发出一个值，然后 .finished")

        Just("Swift")
            .sink { [weak self] completion in
                if case .finished = completion { self?.appendLog("✅ 完成") }
            } receiveValue: { [weak self] value in
                self?.appendLog("📥 值: \(value)")
            }
            .store(in: &cancellables)
    }

    /// Empty：不发出任何值，直接完成
    func demoEmpty() {
        resetLogs()
        appendLog("Empty(completeImmediately: true) → 零个值，直接完成")

        Empty<String, Never>(completeImmediately: true)
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ 完成（没有收到任何值）")
                }
            } receiveValue: { [weak self] _ in
                self?.appendLog("📥 收到值（不应该出现）")
            }
            .store(in: &cancellables)
    }

    /// Fail：不发出值，直接以错误结束
    func demoFail() {
        resetLogs()
        appendLog("Fail(error: .networkError) → 立刻失败")

        enum DemoError: Error, CustomStringConvertible {
            case networkError
            var description: String { "网络不可用" }
        }

        Fail<String, DemoError>(error: .networkError)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.appendLog("❌ 失败: \(error)")
                }
            } receiveValue: { [weak self] value in
                self?.appendLog("📥 值: \(value)")
            }
            .store(in: &cancellables)
    }

    /// Future：包装一次性异步任务（类似 async/await 的回调版）
    func demoFuture() {
        resetLogs()
        appendLog("Future → 模拟异步获取用户名（1 秒后返回）")

        enum DemoError: Error { case timeout }

        // Future 的闭包接收一个 Promise（结果回调）
        // Promise 只能调用一次：.success(value) 或 .failure(error)
        let future = Future<String, DemoError> { promise in
            DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
                promise(.success("用户_张三"))
            }
        }

        future
            .receive(on: DispatchQueue.main) // 回到主线程更新 UI
            .sink { [weak self] completion in
                if case .finished = completion { self?.appendLog("✅ Future 完成") }
            } receiveValue: { [weak self] name in
                self?.appendLog("📥 异步结果: \(name)")
            }
            .store(in: &cancellables)

        appendLog("⏳ 等待 1 秒…")
    }

    /// Deferred：延迟创建 Publisher，每次订阅时才执行闭包
    func demoDeferred() {
        resetLogs()
        appendLog("Deferred → 每次订阅都重新创建内部的 Publisher")

        var counter = 0

        let deferred = Deferred {
            counter += 1
            // 闭包在「有人订阅时」才执行，所以 counter 会递增
            return Just("第 \(counter) 次订阅")
        }

        deferred
            .sink { [weak self] value in
                self?.appendLog("📥 订阅 A: \(value)")
            }
            .store(in: &cancellables)

        deferred
            .sink { [weak self] value in
                self?.appendLog("📥 订阅 B: \(value)")
            }
            .store(in: &cancellables)

        appendLog("注意：A 和 B 收到不同的 counter 值")
    }
}

struct CombinePublishersTutorialView: View {
    @StateObject private var viewModel = CombinePublishersViewModel()

    var body: some View {
        CombineTutorialPage(title: "基础发布者") {
            TutorialConceptCard(
                title: "Publisher 家族",
                content: """
                Publisher 是数据流的源头。Apple 提供了多种内置发布者：
                • Just：发一个值就结束
                • Empty：不发值，直接完成
                • Fail：不发值，直接失败
                • Future：包装一次性异步操作
                • Deferred：懒创建，订阅时才构建内部 Publisher
                """
            )

            publisherDemo("Just", "Just(\"Swift\")", viewModel.demoJust)
            publisherDemo("Empty", "Empty(completeImmediately: true)", viewModel.demoEmpty)
            publisherDemo("Fail", "Fail(error: .networkError)", viewModel.demoFail)
            publisherDemo("Future", "Future { promise in … }", viewModel.demoFuture)
            publisherDemo("Deferred", "Deferred { Just(\"第 N 次\") }", viewModel.demoDeferred)

            TutorialCodeBlock(
                title: "数组 / 序列转 Publisher",
                code: """
                // Sequence 也遵循 Publisher 协议
                [10, 20, 30].publisher
                    .sink { print($0) }  // 依次打印 10, 20, 30

                // 字符串的字符序列
                "ABC".publisher
                    .collect()           // 收集所有值成一个数组
                    .sink { print($0) }  // ["A", "B", "C"]
                """
            )

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }

    private func publisherDemo(_ name: String, _ code: String, _ action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name)
                .font(.headline)
            TutorialCodeBlock(title: "示例", code: code)
            Button("运行 \(name)") { action() }
                .buttonStyle(.bordered)
        }
    }
}
