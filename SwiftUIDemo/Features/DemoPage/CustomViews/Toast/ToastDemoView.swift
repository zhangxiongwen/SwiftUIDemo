//
//  ToastDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct ToastDemoView: View {
    var body: some View {
        List {
            Section("位置") {
                demoRow("Top", subtitle: "顶部") {
                    showToast("顶部 Toast", position: .top)
                }
                demoRow("Center（默认）", subtitle: "居中") {
                    showToast("居中 Toast（默认位置）", position: .center)
                }
                demoRow("Bottom", subtitle: "底部") {
                    showToast("底部 Toast", position: .bottom)
                }
            }

            Section("多行") {
                demoRow("长文案", subtitle: "支持多行居中显示") {
                    showToast("这是一条比较长的提示文案，用来检查在多行时的布局表现是否正常。", position: .center, duration: 3)
                }
            }

            Section("时长") {
                demoRow("0.8s", subtitle: "很短") {
                    showToast("0.8s toast", position: .center, duration: 0.8)
                }
                demoRow("5s", subtitle: "较长") {
                    showToast("5s toast", position: .center, duration: 5)
                }
            }
        }
        .baseNavigationBar(title: "Toast Demo")
    }

    private func demoRow(
        _ title: String,
        subtitle: String,
        action: @escaping () -> Void
    ) -> some View {
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

