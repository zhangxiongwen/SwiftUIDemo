//
//  CombineSwiftUITutorialView.swift
//  SwiftUIDemo
//
//  SwiftUI 集成：@Published、ObservableObject、assign(to:)
//

import Combine
import SwiftUI

// MARK: - 示例 ViewModel（大量注释）

/// 这是 SwiftUI + Combine 最常见的模式：
/// 1. 类遵循 ObservableObject
/// 2. 用 @Published 标记需要驱动 UI 的属性
/// 3. SwiftUI 通过 @StateObject / @ObservedObject 自动订阅变化
@MainActor
final class CounterViewModel: ObservableObject {

    /// @Published 会自动把属性变成 Publisher
    /// 当 count 变化时，所有观察这个 ViewModel 的 View 都会刷新
    @Published var count = 0

    /// 派生属性：用 Combine 管道计算，结果也 @Published
    @Published private(set) var countDescription = "当前: 0"

    private var cancellables = Set<AnyCancellable>()

    init() {
        // $count 是 @Published 生成的 Publisher（Publisher<Int, Never>）
        // 每当 count 变化，map 重新计算，结果赋给 countDescription
        $count
            .map { "当前: \($0)" }
            .assign(to: &$countDescription)
        // assign(to: &$property) 是 iOS 14+ 的便捷写法
        // 等价于 .sink { self.countDescription = $0 }.store(in: &cancellables)
        // 但 assign(to:) 能自动管理生命周期，更简洁
    }

    func increment() { count += 1 }
    func decrement() { count = max(0, count - 1) }
}

/// 演示 assign(to:on:) 旧写法（iOS 13 兼容）
@MainActor
final class TemperatureViewModel: ObservableObject {
    @Published var celsius: Double = 25
    @Published var fahrenheit: Double = 77

    private var cancellables = Set<AnyCancellable>()

    init() {
        $celsius
            .map { celsius in
                celsius * 9 / 5 + 32
            }
            .sink { [weak self] fahrenheit in
                self?.fahrenheit = fahrenheit
            }
            .store(in: &cancellables)
    }
}

// MARK: - 教程页 ViewModel

@MainActor
final class CombineSwiftUIViewModel: ObservableObject, TutorialLogging {
    @Published var logLines: [String] = []

    func explainPublished() {
        resetLogs()
        appendLog("@Published 底层是 CurrentValueSubject")
        appendLog("赋值 count = 5 → 自动通知所有订阅者")
        appendLog("SwiftUI 的 @StateObject 会自动订阅 objectWillChange")
        appendLog("")
        appendLog("三种绑定方式：")
        appendLog("① @StateObject — View 拥有 ViewModel（推荐）")
        appendLog("② @ObservedObject — View 不拥有，由外部传入")
        appendLog("③ @EnvironmentObject — 跨层级共享")
    }

    func explainAssign() {
        resetLogs()
        appendLog("assign(to: &$property) — iOS 14+")
        appendLog("  自动绑定 Publisher → @Published 属性")
        appendLog("")
        appendLog("sink + store — 通用写法")
        appendLog("  适合副作用（弹窗、日志、导航）")
        appendLog("")
        appendLog("assign(to:on:) — iOS 13")
        appendLog("  需要传入对象实例，注意循环引用用 [weak self]")
    }
}

// MARK: - View

struct CombineSwiftUITutorialView: View {
    @StateObject private var tutorialVM = CombineSwiftUIViewModel()
    @StateObject private var counterVM = CounterViewModel()
    @StateObject private var temperatureVM = TemperatureViewModel()

    var body: some View {
        CombineTutorialPage(title: "SwiftUI 集成") {
            TutorialConceptCard(
                title: "Combine + SwiftUI 的关系",
                content: """
                SwiftUI 本身就是基于 Combine 构建的。
                @Published + ObservableObject 是官方推荐的 ViewModel 模式。
                数据流：用户操作 → ViewModel 改 @Published → View 自动刷新。
                """
            )

            TutorialCodeBlock(
                title: "ViewModel 模板",
                code: """
                class MyViewModel: ObservableObject {
                    @Published var items: [Item] = []
                    private var cancellables = Set<AnyCancellable>()

                    func load() {
                        api.fetchItems()
                            .receive(on: DispatchQueue.main)
                            .sink(
                                receiveCompletion: { … },
                                receiveValue: { [weak self] items in
                                    self?.items = items
                                }
                            )
                            .store(in: &cancellables)
                    }
                }
                """
            )

            TutorialDemoActions(runTitle: "讲解 @Published", onRun: tutorialVM.explainPublished)
            TutorialDemoActions(runTitle: "讲解 assign", onRun: tutorialVM.explainAssign)

            TutorialLogPanel(title: "说明", logs: tutorialVM.logLines)

            Divider()

            // 交互演示 1：计数器
            VStack(spacing: 16) {
                Text("演示 1：@Published 驱动 UI")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(counterVM.countDescription)
                    .font(.largeTitle.monospacedDigit())
                    .foregroundStyle(AppColors.primary)

                HStack(spacing: 20) {
                    Button { counterVM.decrement() } label: {
                        Image(systemName: "minus.circle.fill")
                            .font(.title)
                    }
                    Text("\(counterVM.count)")
                        .font(.title.monospacedDigit())
                    Button { counterVM.increment() } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title)
                    }
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // 交互演示 2：温度转换
            VStack(spacing: 12) {
                Text("演示 2：Publisher 链驱动派生属性")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

                HStack {
                    Text("°C")
                    Slider(value: $temperatureVM.celsius, in: -20...50, step: 1)
                    Text("\(Int(temperatureVM.celsius))")
                        .monospacedDigit()
                        .frame(width: 36)
                }

                Text("= \(String(format: "%.1f", temperatureVM.fahrenheit)) °F")
                    .font(.title2)
                    .foregroundStyle(AppColors.primary)
            }
            .padding()
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}
