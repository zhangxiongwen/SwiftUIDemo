//
//  CombineErrorTutorialView.swift
//  SwiftUIDemo
//
//  错误处理：catch、retry、replaceError、mapError
//

import Combine
import SwiftUI

@MainActor
final class CombineErrorViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    private var cancellables = Set<AnyCancellable>()
    private var attemptCount = 0

    enum NetworkError: Error, CustomStringConvertible {
        case timeout
        case serverError
        var description: String {
            switch self {
            case .timeout: return "请求超时"
            case .serverError: return "服务器 500"
            }
        }
    }

    /// 模拟不稳定的网络请求
    private func unstableRequest() -> AnyPublisher<String, NetworkError> {
        attemptCount += 1
        let current = attemptCount

        return Deferred {
            Future<String, NetworkError> { promise in
                DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
                    if current < 3 {
                        promise(.failure(.timeout))
                    } else {
                        promise(.success("数据加载成功 (第 \(current) 次尝试)"))
                    }
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func demoCatch() {
        resetLogs()
        attemptCount = 0
        appendLog("catch：出错后切换到备用 Publisher")

        unstableRequest()
            .catch { [weak self] error -> Just<String> in
                self?.appendLog("⚠️ catch 捕获: \(error)，返回默认值")
                return Just("备用数据")
            }
            .sink { [weak self] completion in
                if case .finished = completion { self?.appendLog("✅ 完成") }
            } receiveValue: { [weak self] data in
                self?.appendLog("📥 结果: \(data)")
            }
            .store(in: &cancellables)
    }

    func demoRetry() {
        resetLogs()
        attemptCount = 0
        appendLog("retry(3)：失败后自动重试，最多 3 次")

        unstableRequest()
            .handleEvents(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.appendLog("❌ 第 \(self?.attemptCount ?? 0) 次失败: \(error)")
                }
            })
            .retry(3)
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ 重试成功，流结束")
                }
            } receiveValue: { [weak self] data in
                self?.appendLog("📥 \(data)")
            }
            .store(in: &cancellables)
    }

    func demoReplaceError() {
        resetLogs()
        appendLog("replaceError：直接把失败变成成功（发出默认值）")

        Fail<String, NetworkError>(error: .serverError)
            .replaceError(with: "离线缓存数据")
            .sink { [weak self] completion in
                if case .finished = completion { self?.appendLog("✅ 完成（错误已被替换）") }
            } receiveValue: { [weak self] data in
                self?.appendLog("📥 \(data)")
            }
            .store(in: &cancellables)
    }

    func demoMapError() {
        resetLogs()
        appendLog("mapError：把一种错误类型映射成另一种")

        Fail<String, NetworkError>(error: .timeout)
            .mapError { networkError -> AppError in
                // 把底层 NetworkError 转成业务层 AppError
                AppError(message: "请检查网络: \(networkError)")
            }
            .sink { [weak self] completion in
                if case .failure(let appError) = completion {
                    self?.appendLog("❌ AppError: \(appError.message)")
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)
    }

    struct AppError: Error {
        let message: String
    }
}

struct CombineErrorTutorialView: View {
    @StateObject private var viewModel = CombineErrorViewModel()

    var body: some View {
        CombineTutorialPage(title: "错误处理") {
            TutorialConceptCard(
                title: "Combine 中的错误",
                content: """
                每个 Publisher 都有 Failure 类型。Never 表示不会失败。
                错误会在 .sink 的 completion 回调中以 .failure(error) 出现。
                操作符可以在管道中间拦截、重试或替换错误。
                """
            )

            TutorialCodeBlock(
                title: "错误处理策略一览",
                code: """
                .catch { error in … }       // 失败后切换到新 Publisher
                .retry(3)                   // 失败后重试 N 次
                .replaceError(with: default) // 失败 → 发出默认值并完成
                .mapError { … }             // 转换错误类型
                """
            )

            errorDemo("catch 兜底", viewModel.demoCatch)
            errorDemo("retry 重试", viewModel.demoRetry)
            errorDemo("replaceError", viewModel.demoReplaceError)
            errorDemo("mapError", viewModel.demoMapError)

            TutorialConceptCard(
                title: "实战建议",
                content: """
                • 网络层用 retry + timeout 组合
                • UI 层用 catch 转成用户友好的提示
                • 需要「必定有值」的场景用 replaceError(with:)
                • 永远不要在 sink 里忽略 .failure 分支
                """
            )

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }

    private func errorDemo(_ name: String, _ action: @escaping () -> Void) -> some View {
        Button("运行 \(name)") { action() }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
