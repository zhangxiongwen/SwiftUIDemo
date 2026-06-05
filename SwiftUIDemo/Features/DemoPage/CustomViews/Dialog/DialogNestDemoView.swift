//
//  DialogNestDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct DialogNestDemoView: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section {
                Text("队列深度：\(navigator.stackDepth)")
                    .foregroundStyle(AppColors.textSecondary)
                Text("present B 时 A 会隐藏（仍在队列里）；关闭 B 后 A 自动重新出现。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("队列演示") {
                demoRow("A → B（B 盖住 A）", subtitle: "先 Alert A，按钮再弹 Alert B") {
                    navigator.presentAlert(
                        title: "A（第 1 层）",
                        message: "点「弹出 B」，A 会隐藏但仍在队列",
                        buttons: [
                            .default("弹出 B") {
                                navigator.presentAlert(
                                    title: "B（第 2 层）",
                                    message: "关闭我之后，A 会自动回来",
                                    buttons: [
                                        .default("再弹出 C") {
                                            navigator.presentActionSheet(
                                                title: "C（第 3 层 ActionSheet）",
                                                buttons: [
                                                    .default("关闭 C，回到 B") { navigator.dismiss() }
                                                ]
                                            )
                                        },
                                        .cancel("关闭 B，回到 A") { navigator.dismiss() }
                                    ]
                                )
                            },
                            .cancel("关闭 A") { navigator.dismiss() }
                        ]
                    )
                }

                demoRow("ActionSheet → Alert", subtitle: "底层 ActionSheet，上层 Alert") {
                    navigator.presentActionSheet(
                        title: "A · ActionSheet",
                        message: "弹出 Alert 后本层隐藏",
                        buttons: [
                            .default("弹出 Alert B") {
                                navigator.presentAlert(
                                    title: "B · Alert",
                                    message: "关闭后恢复 ActionSheet",
                                    buttons: [.cancel("关闭 B") { navigator.dismiss() }]
                                )
                            }
                        ]
                    )
                }

                demoRow("无限入队", subtitle: "每层关闭后回到上一层") {
                    presentQueuedAlert(level: 1)
                }
            }

            Section("手动控制") {
                demoRow("入队 Alert", subtitle: "depth = \(navigator.stackDepth + 1)") {
                    navigator.presentAlert(
                        title: "Alert L?\(navigator.stackDepth + 1)",
                        buttons: queueButtons(type: "Alert")
                    )
                }

                demoRow("入队 ActionSheet", subtitle: "depth = \(navigator.stackDepth + 1)") {
                    navigator.presentActionSheet(
                        title: "Sheet L?\(navigator.stackDepth + 1)",
                        buttons: queueButtons(type: "Sheet")
                    )
                }

                demoRow("出队顶层", subtitle: "dismiss()") {
                    navigator.dismiss()
                }

                demoRow("清空队列", subtitle: "dismissAllDialog", destructive: true) {
                    navigator.dismissAllDialog()
                }
            }
        }
        .baseNavigationBar(title: "Dialog 队列")
        .navigator(navigator)
    }

    private func queueButtons(type: String) -> [DialogButton] {
        let depth = navigator.stackDepth
        return [
            .default("再入队 \(type)") {
                if type == "Alert" {
                    presentQueuedAlert(level: depth + 1)
                } else {
                    navigator.presentActionSheet(
                        title: "\(type) L?\(depth + 1)",
                        buttons: queueButtons(type: type)
                    )
                }
            },
            .cancel("关闭当前层") { navigator.dismiss() }
        ]
    }

    private func presentQueuedAlert(level: Int) {
        navigator.presentAlert(
            title: "Alert 第 \(level) 层",
            message: level >= 5 ? "队列已经很深了" : "可继续入队下一层",
            buttons: queueButtons(type: "Alert")
        )
    }

    private func demoRow(
        _ title: String,
        subtitle: String,
        destructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(destructive ? AppColors.error : AppColors.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
    }
}
