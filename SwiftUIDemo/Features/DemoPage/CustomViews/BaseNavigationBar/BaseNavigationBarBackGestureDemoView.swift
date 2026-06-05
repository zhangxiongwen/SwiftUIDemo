//
//  BaseNavigationBarBackGestureDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct BaseNavigationBarBackGestureDemoView: View {
    @State private var navigator = Navigator()

    @State private var allowsSwipeBack = true
    @State private var useInterceptBack = true

    var body: some View {
        List {
            Section("侧滑返回") {
                Toggle("允许侧滑返回（默认开启）", isOn: $allowsSwipeBack)
            }

            Section("返回按钮拦截") {
                Toggle("自定义 onBack（拦截点击事件）", isOn: $useInterceptBack)
                Text(useInterceptBack
                     ? "开启后：返回按钮会先弹窗确认；同时默认禁用侧滑，避免系统 pop 绕过你的逻辑。"
                     : "关闭后：返回按钮使用默认 navigator.back()；侧滑返回也可用。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }

            Section("说明") {
                Text("如果你既要拦截返回按钮，又要允许侧滑，请把 allowsSwipeBack 设为 true，并自行接受“侧滑不会走 onBack”这一点。")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .baseNavigationBar(
            title: "手势返回 & 拦截",
            allowsSwipeBack: allowsSwipeBack,
            onBack: useInterceptBack ? confirmBack : nil
        )
        .navigator(navigator)
    }

    private func confirmBack() {
        navigator.presentAlert(
            title: "确认返回？",
            message: "这里模拟“有未保存内容/需要埋点/需要二次确认”的场景。",
            buttons: [
                .cancel { navigator.dismiss() },
                .destructive("返回") {
                    navigator.dismiss {
                        navigator.back()
                    }
                }
            ]
        )
    }
}
