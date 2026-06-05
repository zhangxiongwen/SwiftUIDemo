//
//  LoadingDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct LoadingDemoView: View {
    var body: some View {
        List {
            Section("showLoading / hideLoading") {
                demoRow("显示 2s", subtitle: "showLoading 后 Task 里 hideLoading") {
                    showLoading()
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        hideLoading()
                    }
                }

                demoRow("自定义文案", subtitle: "showLoading(\"正在上传...\")") {
                    showLoading("100张图片正在疯狂加速上传...")
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        hideLoading()
                    }
                }
                
                demoRow("自定义文案", subtitle: "文字很长很长") {
                    showLoading("图片正在疯狂加速上传图片正在疯狂加速上传.图片正在疯狂加速上传.图片正在疯狂加速上传.")
                    Task { @MainActor in
                        try? await Task.sleep(for: .seconds(2))
                        hideLoading()
                    }
                }

                demoRow("仅 showLoading", subtitle: "默认「加载中...」；最多 60s 自动关闭") {
                    showLoading()
                }

                demoRow("hideLoading", subtitle: "关闭当前全局 Loading") {
                    hideLoading()
                }
            }

            Section("说明") {
                Text("根视图已挂载 .appHUDConfig()。任意页面（含 present）调用 showLoading() 即可。超过 60 秒会自动 hideLoading。")
                    .appFont(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .baseNavigationBar(title: "Loading Demo")
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
