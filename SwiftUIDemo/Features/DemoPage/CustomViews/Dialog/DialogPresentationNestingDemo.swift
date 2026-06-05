//
//  DialogPresentationNestingDemo.swift
//  SwiftUIDemo
//
//  展示 ViewPresenter 自定义弹窗与系统 .alert / .sheet / fullScreenCover 的嵌套效果。
//

import SwiftUI

// MARK: - 自定义 Alert → 系统 Alert → 系统 Sheet

struct CustomToSystemNestingDemoCard: View {
    @State private var navigator = Navigator()
    @State private var showSystemAlert = false
    @State private var showSystemSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            nestingLayerBadge("第 1 层", detail: "ViewPresenter 自定义 Alert（fullScreenCover）")

            Text("真实 SwiftUI `.alert`：点按钮后系统会 dismiss，再开 `.sheet` 时 Alert 通常已消失（平台行为）。")
                .appFont(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)

            Button("弹出系统 Alert（第 2 层）") {
                showSystemAlert = true
            }
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity)

            Button("关闭第 1 层") {
                navigator.dismiss()
            }
            .buttonStyle(.bordered)
            .frame(maxWidth: .infinity)
        }
        .padding(20)
        .frame(maxWidth: 320)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
        .alert("第 2 层：系统 Alert", isPresented: $showSystemAlert) {
            Button("弹出系统 Sheet（第 3 层）") {
                showSystemSheet = true
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("SwiftUI `.alert`，叠在自定义 Dialog 的 fullScreenCover 上。")
        }
        .sheet(isPresented: $showSystemSheet) {
            SystemSheetNestingDemoContent()
        }
        .navigator(navigator)
    }
}

private struct SystemSheetNestingDemoContent: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    nestingLayerBadge("第 3 层", detail: "系统 .sheet")
                    Text("由系统 Alert 的按钮打开；Alert 点按钮后已被系统 dismiss。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle("系统 Sheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("关闭 Sheet") { dismiss() }
                }
            }
        }
    }
}

// MARK: - 【系统 A】presentPage + dialogStack  vs  【系统 B】页面内 fullScreenCover

struct CustomModalNestingRootView: View {
    @State private var navigator = Navigator()
    @State private var showNestedFullScreenCover = false

    var body: some View {
        NavigationStack {
            List {
                Section("两套 Presentation") {
                    nestingLayerBadge("A·第 1 层", detail: "navigator.presentPage → pageCover")
                    Text("ViewPresenter 宿主：整页 Cover 占 pageCover 槽，不关第 1 层就不会卸掉。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("其上的 Alert / ActionSheet / custom 走 dialogStack，叠在整页之上。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("【系统 B】本页 @State + SwiftUI .fullScreenCover 是另一套，画在 pageCover 子树里，不进 dialogStack。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Section("【系统 A】dialogStack") {
                    Button {
                        navigator.presentCommonAlert(
                            title: "A·第 2 层：dialogStack Alert",
                            message: "叠在 pageCover 整页之上；关 Alert 后第 1 层 Cover 仍在。",
                            confirmBtnText: "知道了"
                        )
                    } label: {
                        demoLabel(
                            title: "A·弹 navigator Alert",
                            code: "navigator.presentCommonAlert(...)"
                        )
                    }
                }

                Section("【系统 B】页面内 SwiftUI") {
                    Button {
                        showNestedFullScreenCover = true
                    } label: {
                        demoLabel(
                            title: "B·弹页面内 fullScreenCover",
                            code: ".fullScreenCover(isPresented:) { … }"
                        )
                    }
                    Text("不占用 pageCover，也不进 dialogStack；与第 1 层并行存在。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .navigationTitle("两套系统对照")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭 A·整页 Cover") { navigator.back() }
                }
            }
        }
        .fullScreenCover(isPresented: $showNestedFullScreenCover) {
            CustomModalNestingSecondCoverView()
        }
        .navigator(navigator)
    }
}

private struct CustomModalNestingSecondCoverView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigator = Navigator()

    var body: some View {
        NavigationStack {
            List {
                Section("当前所在层") {
                    nestingLayerBadge("B·第 3 层", detail: "SwiftUI .fullScreenCover（页面内）")
                    Text("你在【系统 B】里。这一层由本页 @State 控制，与 dialogStack 无关。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Section("跨系统叠加（易误解）") {
                    Text("下面按钮走【系统 A】navigator → 弹窗画在 ViewPresenter 宿主最顶上，会盖住整块 pageCover（含本层 B）。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("视觉上像「B 被 Alert 替换」；关 Alert 后 B 一般仍在（showNestedFullScreenCover 未变）。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("若希望第 4 层也在同一队列，请用 navigator.presentCustomView / presentPage，别混用 B。")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    Button {
                        navigator.presentAlert(
                            title: "A·第 4 层：dialogStack Alert",
                            message: "画在 ViewPresenter 宿主顶层，盖住 B·页面内 Cover；dismiss 后应回到 B。",
                            buttons: [
                                .default("关闭 A·Alert") { navigator.dismiss() }
                            ]
                        )
                    } label: {
                        demoLabel(
                            title: "A·再弹 navigator Alert（盖住 B）",
                            code: "navigator.presentAlert(...)"
                        )
                    }
                }
            }
            .navigationTitle("B·页面内 Cover")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭 B·页面内 Cover") { dismiss() }
                }
            }
        }
        .navigator(navigator)
    }
}

// MARK: - Shared UI

private func nestingLayerBadge(_ layer: String, detail: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        Text(layer)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.primary)
            .clipShape(Capsule())

        Text(detail)
            .appFont(AppFonts.body)
            .foregroundStyle(AppColors.textPrimary)
    }
}

private func demoLabel(title: String, code: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
        Text(title)
            .foregroundStyle(AppColors.textPrimary)
        Text(code)
            .font(.system(.caption, design: .monospaced))
            .foregroundStyle(AppColors.textSecondary)
    }
}
