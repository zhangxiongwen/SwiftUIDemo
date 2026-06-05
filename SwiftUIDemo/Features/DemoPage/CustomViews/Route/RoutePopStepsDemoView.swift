//
//  RoutePopStepsDemoView.swift
//  SwiftUIDemo
//
//  演示 navigator.pop() / pop(steps:) / popToRoot()。
//

import SwiftUI

struct RoutePopStepsDemoView: View {
    @State private var navigator = Navigator()
    let layer: Int

    var body: some View {
        List {
            Section("当前栈") {
                LabeledContent("本页 layer", value: "\(layer)")
                LabeledContent("pushDepth", value: "\(navigator.pushDepth)")
                Text("先连 push 到第 3 层，再试 pop(steps: 2) 一次退回 2 页。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("继续 push") {
                Button {
                    navigator.push(
                        CustomViewsRoute.routePopStepsDemo,
                        query: ["layer": "\(layer + 1)"]
                    )
                } label: {
                    popDemoLabel(
                        title: "→ 第 \(layer + 1) 层",
                        code: "navigator.push(.routePopStepsDemo, query: [\"layer\": \"\(layer + 1)\"])"
                    )
                }
            }

            Section("pop") {
                Button {
                    navigator.pop()
                } label: {
                    popDemoLabel(title: "后退 1 页", code: "navigator.pop()")
                }

                Button {
                    navigator.pop(steps: 2)
                } label: {
                    popDemoLabel(title: "后退 2 页", code: "navigator.pop(steps: 2)")
                }

                Button {
                    navigator.popToRoot()
                } label: {
                    popDemoLabel(title: "回到栈根", code: "navigator.popToRoot()")
                }
            }
        }
        .baseNavigationBar(title: "Pop 第 \(layer) 层")
        .navigator(navigator)
        .navigatorRouterScope(navigator)
    }

    private func popDemoLabel(title: String, code: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .foregroundStyle(AppColors.textPrimary)
            Text(code)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}
