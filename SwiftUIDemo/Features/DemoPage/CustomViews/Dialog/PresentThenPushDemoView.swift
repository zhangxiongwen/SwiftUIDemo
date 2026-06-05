//
//  PresentThenPushDemoView.swift
//  SwiftUIDemo
//
//  试验：Alert / Sheet / fullScreenCover 未关闭时 navigator.push 的实际表现。
//

import SwiftUI

// MARK: - 入口页

struct PresentThenPushDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("说明") {
                Text("present 出来的层和根 NavigationStack 是两套 UI 树。在弹层里调外层 navigator.push，路径会变，但新页画在弹层下面，所以像「不能 push」。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                Text("要在 present 的模块里继续跳转：像模版 App 一样，在 Cover 内再包一层 NavigationStack + 自己的 router（见下方 ④）。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                if navigator.isPresentingStack {
                    Text("本页 navigator：弹窗栈 \(navigator.stackDepth) 层 · Cover \(navigator.isPresentingPage ? "开" : "关")")
                        .font(.caption)
                        .foregroundStyle(AppColors.primary)
                }
            }

            Section("打开弹层（再在里面 push）") {
                demoRow("① 自定义 Alert", subtitle: "presentAlert + 自定义 content") {
                    navigator.presentAlert(
                        title: "Alert 层",
                        message: "点击下方 push，不要先关我。",
                        content: { PresentThenPushActions(from: "alert", layerName: "Alert") },
                        buttons: [
                            .cancel("关闭 Alert") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("② 自定义 Sheet", subtitle: "presentCustomView(style: .sheet)") {
                    navigator.presentCustomView(style: .sheet, dismissOnBackgroundTap: true) {
                        PresentThenPushSheetLayer(from: "sheet")
                    }
                }

                demoRow("③ presentPage", subtitle: "无内层导航 · 外层 push 被挡") {
                    navigator.presentPage {
                        PresentThenPushCoverLayer(from: "cover")
                    }
                }
            }

            Section("正确：presentNavigationPage") {
                demoRow("④ 带独立导航", subtitle: "同 Dialog 整页 Present Demo") {
                    navigator.presentNavigationPage {
                        PresentNavigationPageDemoRootView()
                    }
                }
            }

            Section("对照：无弹层直接 push") {
                demoRow("直接 push 目标页", subtitle: "不打开任何弹窗") {
                    navigator.push(CustomViewsRoute.presentThenPushTarget, query: ["from": "none"])
                }
            }
        }
        .baseNavigationBar(title: "弹层中 Push 试验")
        .navigator(navigator)
    }

    private func demoRow(_ title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}

// MARK: - 弹层内操作区

private struct PresentThenPushActions: View {
    @State private var navigator = Navigator()
    let from: String
    let layerName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前在 \(layerName) 内")
                .appFont(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button {
                navigator.push(CustomViewsRoute.presentThenPushTarget, query: ["from": from])
            } label: {
                Label("外层 navigator.push（不 dismiss）", systemImage: "exclamationmark.triangle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Text("path 已 append，但目标页在弹层下面，看起来像 push 失败。")
                .font(.caption2)
                .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .navigator(navigator)
    }
}

// MARK: - Sheet 层

private struct PresentThenPushSheetLayer: View {
    @State private var navigator = Navigator()
    let from: String

    var body: some View {
        NavigationStack {
            List {
                Section {
                    nestingBadge("第 2 层", detail: "presentCustomView(.sheet)")
                    PresentThenPushActions(from: from, layerName: "Sheet")
                }
            }
            .navigationTitle("Sheet 层")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭 Sheet") { navigator.dismiss() }
                }
            }
        }
        .navigator(navigator)
    }
}

// MARK: - presentPage（无内层导航，错误示范）

private struct PresentThenPushCoverLayer: View {
    @State private var navigator = Navigator()
    let from: String

    var body: some View {
        NavigationStack {
            List {
                Section {
                    nestingBadge("第 2 层", detail: "presentPage")
                    PresentThenPushActions(from: from, layerName: "fullScreenCover")
                }
            }
            .navigationTitle("Cover 层")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭 Cover") { navigator.back() }
                }
            }
        }
        .navigator(navigator)
    }
}

// MARK: - Shared

private func nestingBadge(_ layer: String, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(layer)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.primary)
            .clipShape(Capsule())
        Text(detail)
            .appFont(AppFonts.caption)
            .foregroundStyle(AppColors.textSecondary)
    }
}
