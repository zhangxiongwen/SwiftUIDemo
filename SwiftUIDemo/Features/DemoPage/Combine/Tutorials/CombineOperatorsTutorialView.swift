//
//  CombineOperatorsTutorialView.swift
//  SwiftUIDemo
//
//  变换与过滤操作符：map、filter、compactMap、scan、removeDuplicates、debounce、throttle
//

import Combine
import SwiftUI

@MainActor
final class CombineOperatorsViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []
    @Published var searchText = ""
    @Published var debouncedResult = "（等待输入…）"
    private var cancellables = Set<AnyCancellable>()

    private let searchSubject = PassthroughSubject<String, Never>()

    init() {
        // 实战：搜索框防抖 — 用户停止输入 0.5 秒后才触发
        searchSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                self?.debouncedResult = text.isEmpty ? "（空）" : "搜索: \"\(text)\""
                self?.appendLog("🔍 debounce 触发: \"\(text)\"")
            }
            .store(in: &cancellables)

        // 绑定 SwiftUI TextField 到 Subject
        $searchText
            .sink { [weak self] text in
                self?.searchSubject.send(text)
            }
            .store(in: &cancellables)
    }

    func demoMapFilter() {
        resetLogs()
        appendLog("map + filter：只保留偶数并平方")

        let numbers = (1...6).publisher

        numbers
            .filter { $0 % 2 == 0 }   // 只留 2, 4, 6
            .map { $0 * $0 }            // 平方 → 4, 16, 36
            .sink { [weak self] value in
                self?.appendLog("📥 \(value)")
            }
            .store(in: &cancellables)
    }

    func demoCompactMap() {
        resetLogs()
        appendLog("compactMap：把 String 转 Int，失败的自动丢弃")

        let strings = ["10", "abc", "20", "30x", "40"].publisher

        strings
            .compactMap { Int($0) }  // "abc" 和 "30x" 被丢弃
            .sink { [weak self] number in
                self?.appendLog("📥 有效数字: \(number)")
            }
            .store(in: &cancellables)
    }

    func demoScan() {
        resetLogs()
        appendLog("scan：累加求和（类似 reduce，但每步都发出中间结果）")

        [1, 2, 3, 4, 5].publisher
            .scan(0, +)  // 0+1=1, 1+2=3, 3+3=6, 6+4=10, 10+5=15
            .sink { [weak self] sum in
                self?.appendLog("📥 累计: \(sum)")
            }
            .store(in: &cancellables)
    }

    func demoRemoveDuplicates() {
        resetLogs()
        appendLog("removeDuplicates：连续重复值只保留第一个")

        ["A", "A", "B", "B", "B", "C", "A"].publisher
            .removeDuplicates()
            .sink { [weak self] char in
                self?.appendLog("📥 \(char)")
            }
            .store(in: &cancellables)
    }

    func demoThrottle() {
        resetLogs()
        appendLog("throttle：1 秒内只取第一个事件（适合按钮连点）")

        let rapidClicks = PassthroughSubject<Int, Never>()

        rapidClicks
            .throttle(for: .seconds(1), scheduler: RunLoop.main, latest: false)
            .sink { [weak self] click in
                self?.appendLog("✅ 有效点击 #\(click)")
            }
            .store(in: &cancellables)

        // 模拟快速连点
        for i in 1...5 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                self.appendLog("👆 原始点击 #\(i)")
                rapidClicks.send(i)
            }
        }
    }
}

struct CombineOperatorsTutorialView: View {
    @StateObject private var viewModel = CombineOperatorsViewModel()

    var body: some View {
        CombineTutorialPage(title: "变换与过滤") {
            TutorialConceptCard(
                title: "Operator 操作符",
                content: """
                操作符是 Publisher 的扩展方法，返回新的 Publisher。
                你可以像搭管道一样串联：publisher.map { }.filter { }.debounce { }
                每个操作符只负责一件事，组合起来就能处理复杂逻辑。
                """
            )

            operatorDemo("map + filter", "filter { $0 % 2 == 0 }.map { $0 * $0 }", viewModel.demoMapFilter)
            operatorDemo("compactMap", "compactMap { Int($0) }", viewModel.demoCompactMap)
            operatorDemo("scan 累加", "scan(0, +)", viewModel.demoScan)
            operatorDemo("removeDuplicates", "removeDuplicates()", viewModel.demoRemoveDuplicates)
            operatorDemo("throttle 节流", "throttle(for: .seconds(1), …)", viewModel.demoThrottle)

            Divider()

            TutorialConceptCard(
                title: "debounce vs throttle",
                content: """
                debounce（防抖）：等用户「停下来」一段时间后才触发。适合搜索框。
                throttle（节流）：固定时间窗口内只取第一个/最后一个。适合滚动、按钮连点。
                """
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("实时演示：搜索防抖")
                    .font(.headline)
                TextField("输入搜索关键词…", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                Text("debounce 结果: \(viewModel.debouncedResult)")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }

            TutorialLogPanel(title: "运行日志", logs: viewModel.logLines)

            Button("清空日志") { viewModel.resetLogs() }
                .buttonStyle(.bordered)
        }
    }

    private func operatorDemo(_ name: String, _ code: String, _ action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(name).font(.headline)
            TutorialCodeBlock(title: "示例", code: code)
            Button("运行 \(name)") { action() }
                .buttonStyle(.bordered)
        }
    }
}
