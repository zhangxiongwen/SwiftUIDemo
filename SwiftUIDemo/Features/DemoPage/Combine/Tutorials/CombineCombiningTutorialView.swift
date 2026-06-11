//
//  CombineCombiningTutorialView.swift
//  SwiftUIDemo
//
//  组合多个流：combineLatest、merge、zip
//

import Combine
import SwiftUI

@MainActor
final class CombineCombiningViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    @Published var username = ""
    @Published var password = ""
    @Published var canLogin = false
    private var cancellables = Set<AnyCancellable>()

    init() {
        // 实战：combineLatest 做表单验证
        // 当 username 或 password 任一变化时，重新计算 canLogin
        Publishers.CombineLatest($username, $password)
            .map { user, pass in
                // 用户名 ≥ 3 且密码 ≥ 6 才可登录
                user.count >= 3 && pass.count >= 6
            }
            .removeDuplicates()
            .sink { [weak self] valid in
                self?.canLogin = valid
                self?.appendLog("🔐 登录按钮: \(valid ? "可用" : "禁用")")
            }
            .store(in: &cancellables)
    }

    func demoCombineLatest() {
        resetLogs()
        appendLog("combineLatest：任一上游更新，就发出「最新组合」")

        let temp = PassthroughSubject<Int, Never>()
        let humidity = PassthroughSubject<Int, Never>()

        Publishers.CombineLatest(temp, humidity)
            .sink { [weak self] t, h in
                self?.appendLog("🌡 温度 \(t)°C + 湿度 \(h)%")
            }
            .store(in: &cancellables)

        temp.send(25)
        humidity.send(60)   // 发出 (25, 60)
        temp.send(28)       // 发出 (28, 60) — 湿度保持上次值
        humidity.send(55)   // 发出 (28, 55)
    }

    func demoMerge() {
        resetLogs()
        appendLog("merge：把多个同类型流合并成一个（谁先 emit 谁先出）")

        let streamA = PassthroughSubject<String, Never>()
        let streamB = PassthroughSubject<String, Never>()

        streamA.merge(with: streamB)
            .sink { [weak self] value in
                self?.appendLog("📥 \(value)")
            }
            .store(in: &cancellables)

        streamA.send("来自 A-1")
        streamB.send("来自 B-1")
        streamA.send("来自 A-2")
        streamB.send("来自 B-2")
    }

    func demoZip() {
        resetLogs()
        appendLog("zip：按索引配对，短的那个结束就停止")

        let names = ["张三", "李四", "王五"].publisher
        let scores = [90, 85].publisher  // 只有 2 个分数

        names.zip(scores)
            .sink { [weak self] completion in
                if case .finished = completion {
                    self?.appendLog("✅ zip 结束（较短流耗尽）")
                }
            } receiveValue: { [weak self] name, score in
                self?.appendLog("📥 \(name): \(score) 分")
            }
            .store(in: &cancellables)
    }
}

struct CombineCombiningTutorialView: View {
    @StateObject private var viewModel = CombineCombiningViewModel()

    var body: some View {
        CombineTutorialPage(title: "组合多个流") {
            TutorialConceptCard(
                title: "什么时候用哪个？",
                content: """
                combineLatest：需要「各流的最新值」组合计算（表单验证、仪表盘）。
                merge：多个来源产生同类型事件，合并监听（多路日志、多通知源）。
                zip：严格按顺序一一配对（下载进度+文件名、问答配对）。
                """
            )

            combiningDemo("combineLatest", "Publishers.CombineLatest(a, b)", viewModel.demoCombineLatest)
            combiningDemo("merge", "a.merge(with: b)", viewModel.demoMerge)
            combiningDemo("zip", "names.zip(scores)", viewModel.demoZip)

            Divider()

            TutorialConceptCard(
                title: "实战：登录表单验证",
                content: "下面用 combineLatest 监听用户名和密码，实时决定登录按钮是否可用。"
            )

            VStack(alignment: .leading, spacing: 12) {
                TextField("用户名（≥3 字符）", text: $viewModel.username)
                    .textFieldStyle(.roundedBorder)
                SecureField("密码（≥6 字符）", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)

                Button("登录") {}
                    .buttonStyle(.borderedProminent)
                    .disabled(!viewModel.canLogin)

                Text(viewModel.canLogin ? "✅ 可以登录" : "⛔ 请完善信息")
                    .font(.caption)
                    .foregroundStyle(viewModel.canLogin ? AppColors.success : AppColors.textSecondary)
            }

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)
        }
    }

    private func combiningDemo(_ name: String, _ code: String, _ action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline)
            TutorialCodeBlock(title: "示例", code: code)
            Button("运行 \(name)") { action() }
                .buttonStyle(.bordered)
        }
    }
}
