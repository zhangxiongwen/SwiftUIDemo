//
//  DialogDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct DialogDemoView: View {
    
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section("说明") {
                Text("本页 @State navigator + .navigator(navigator)；push / present 统一走 Navigator。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("嵌套试验") {
                demoRow("Dialog 队列 Demo", subtitle: "present B 隐藏 A，关 B 自动恢复 A") {
                    navigator.push(CustomViewsRoute.dialogNestDemo)
                }
                demoRow("弹层未关时 Push", subtitle: "Alert / 自定义 Sheet / Cover 内 navigator.push") {
                    navigator.push(CustomViewsRoute.presentThenPushDemo)
                }
            }

            Section("嵌套：自定义 × 系统") {
                nestingDemoRow(
                    title: "自定义 Alert → 系统 Alert → 系统 Sheet",
                    code: """
                    presentCustomView(style: .alert) { … }
                      → .alert { … }
                      → .sheet { … }
                    """
                ) {
                    navigator.presentCustomView(style: .alert, dismissOnBackgroundTap: false) {
                        CustomToSystemNestingDemoCard()
                    }
                }
            }

            Section("嵌套：自定义 × 自定义（两套系统）") {
                nestingDemoRow(
                    title: "ViewPresenter Cover + 页面内 fullScreenCover",
                    code: """
                    【A】presentPage → dialogStack Alert
                    【B】.fullScreenCover → 再调 navigator Alert 会盖住 B
                    """
                ) {
                    navigator.presentPage {
                        CustomModalNestingRootView()
                    }
                }
            }

            Section("嵌套：Cover 内 navigator") {
                nestingDemoRow(
                    title: "Cover → 子页再弹 Alert",
                    code: """
                    presentPage { … }
                    // Cover 内 @State navigator + .navigator
                    """
                ) {
                    navigator.presentPage {
                        CoverWithNavigatorDemoView()
                    }
                }
            }

            Section("Alert（fullScreenCover）") {
                demoRow("presentCommonAlert", subtitle: "通用双按钮") {
                    navigator.presentCommonAlert(
                        title: "保存修改？",
                        message: "当前编辑内容尚未保存，离开后将丢失。",
                        cancelBtnText: "取消",
                        confirmBtnText: "保存"
                    )
                }

                demoRow("presentAlert 双按钮", subtitle: "dismiss(complete:)") {
                    navigator.presentAlert(
                        title: "保存修改？",
                        message: "当前编辑内容尚未保存，离开后将丢失。",
                        buttons: [
                            .cancel { navigator.dismiss() },
                            .default("保存") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("三按钮（纵向）") {
                    navigator.presentAlert(
                        title: "检测到新版本",
                        message: "v2.1.0 已发布，是否立即更新？",
                        buttons: [
                            .default("立即更新") { navigator.dismiss() },
                            .default("稍后提醒") { navigator.dismiss() },
                            .cancel("忽略") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("presentCommonAlert + content") {
                    navigator.presentCommonAlert(
                        title: "绑定手机号",
                        content: {
                            HStack(spacing: 8) {
                                Text("+86")
                                    .foregroundStyle(AppColors.textSecondary)
                                Text("138 **** 8888")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.background)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        },
                        confirmBtnText: "确认绑定"
                    )
                }

                demoRow("自定义 View（Alert 样式）") {
                    navigator.presentCustomView(style: .alert, dismissOnBackgroundTap: true) {
                        customAlertCard
                    }
                }

                demoRow("Destructive") {
                    navigator.presentAlert(
                        title: "删除账号？",
                        message: "此操作不可恢复，所有数据将被永久删除。",
                        buttons: [
                            .cancel { navigator.dismiss() },
                            .destructive("删除") { navigator.dismiss() }
                        ]
                    )
                }
            }

            Section("ActionSheet（fullScreenCover 底部样式）") {
                demoRow("基础 ActionSheet") {
                    navigator.presentActionSheet(
                        title: "更换头像",
                        message: "请选择图片来源",
                        buttons: [
                            .default("拍照") { navigator.dismiss() },
                            .default("从相册选择") { navigator.dismiss() },
                            .destructive("删除当前头像") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("带取消按钮") {
                    navigator.presentActionSheet(
                        title: "确认操作",
                        buttons: [
                            .default("继续") { navigator.dismiss() },
                            .cancel("暂不") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("自定义 Content（图片）") {
                    navigator.presentActionSheet(
                        title: "分享海报",
                        message: "长按可保存到相册",
                        content: {
                            Image(systemName: "photo.artframe")
                                .font(.system(size: 72))
                                .foregroundStyle(AppColors.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                                .background(AppColors.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        },
                        buttons: [
                            .default("保存图片") { navigator.dismiss() },
                            .default("分享到微信") { navigator.dismiss() }
                        ]
                    )
                }
            }

            Section("Custom View（Sheet 底部样式）") {
                demoRow("presentCustomView(style: .sheet)") {
                    navigator.presentCustomView(style: .sheet, dismissOnBackgroundTap: true) {
                        VStack(spacing: 12) {
                            HStack {
                                Text("自定义 Sheet")
                                    .appFont(AppFonts.h2)
                                Spacer()
                                Button("关闭") { navigator.dismiss() }
                                    .buttonStyle(.bordered)
                            }
                            Text("底部上滑样式，走 fullScreenCover 队列。")
                                .appFont(AppFonts.caption)
                                .foregroundStyle(AppColors.textSecondary)
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(
                            UnevenRoundedRectangle(
                                topLeadingRadius: 16,
                                topTrailingRadius: 16,
                                style: .continuous
                            )
                        )
                    }
                }
            }
        }
        .baseNavigationBar(title: "Dialog & ActionSheet")
        .navigator(navigator)
    }

    private var customAlertCard: some View {
        VStack(spacing: 12) {
            Text("完全自定义弹窗")
                .appFont(AppFonts.h2)
            Text("按钮里调用 navigator.dismiss()")
                .appFont(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
            HStack(spacing: 12) {
                Button("关闭") { navigator.dismiss() }
                    .buttonStyle(.bordered)
                Button("再弹一层") {
                    navigator.presentCustomView(style: .alert, dismissOnBackgroundTap: true) {
                        VStack(spacing: 12) {
                            Text("第二层")
                                .appFont(AppFonts.h2)
                            Button("关闭") { navigator.dismiss() }
                                .buttonStyle(.borderedProminent)
                        }
                        .padding(16)
                        .frame(maxWidth: 280)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
        .frame(maxWidth: 320)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func demoRow(
        _ title: String,
        subtitle: String? = nil,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
    }

    private func nestingDemoRow(
        title: String,
        code: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .foregroundStyle(AppColors.textPrimary)
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - 嵌套 Cover

private struct CoverWithNavigatorDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        NavigationStack {
            List {
                Button("再弹 Alert（同一 navigator）") {
                    navigator.presentAlert(
                        title: "第 2 层 Alert",
                        message: "Cover 内 @State navigator + .navigator。",
                        buttons: [
                            .default("关闭") { navigator.dismiss() }
                        ]
                    )
                }
            }
            .navigationTitle("第 1 层 Cover")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭 Cover") { navigator.back() }
                }
            }
        }
        .navigator(navigator)
    }
}
