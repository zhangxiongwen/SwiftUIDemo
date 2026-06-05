//
//  LoadingManager.swift
//  SwiftUIDemo
//
//  HUD / Loading
//
//  全局 Loading 状态；根视图 `.appHUDConfig()` + `showLoading()` / `hideLoading()`。
//

import SwiftUI

/// 全局 Loading 单例状态机，由 `LoadingHostModifier` 订阅并渲染。
@Observable
class LoadingManager {
    static let shared = LoadingManager()

    /// 是否正在展示 Loading。
    var isShowing: Bool = false
    /// 转圈下方文案；传空字符串则只显示 Progress。
    var message: String = "加载中..."

    private var timeoutWorkItem: DispatchWorkItem?

    private init() {}

    /// 显示全局 Loading 并阻塞交互。
    /// - Parameters:
    ///   - message: 文案，默认「加载中...」。
    ///   - maxDuration: 最长展示时间，超时自动 `hide()`，默认 60s。
    func show(
        _ message: String = "加载中...",
        maxDuration: TimeInterval = LoadingMetrics.maxDuration
    ) {
        timeoutWorkItem?.cancel()

        if isShowing {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.message = message
                isShowing = true
            }
        } else {
            withAnimation(.easeInOut(duration: LoadingMetrics.fadeDuration)) {
                self.message = message
                isShowing = true
            }
        }

        scheduleAutoHide(after: maxDuration)
    }

    /// 关闭 Loading 并取消超时计时。
    func hide() {
        timeoutWorkItem?.cancel()
        withAnimation(.easeInOut(duration: LoadingMetrics.fadeDuration)) {
            isShowing = false
        }
    }

    private func scheduleAutoHide(after duration: TimeInterval) {
        let task = DispatchWorkItem { [weak self] in
            self?.hide()
        }
        timeoutWorkItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

/// 显示全局 Loading（需根视图已调用 `.appHUDConfig()`）。
@MainActor
func showLoading(
    _ message: String = "加载中...",
    maxDuration: TimeInterval = LoadingMetrics.maxDuration
) {
    LoadingManager.shared.show(message, maxDuration: maxDuration)
}

/// 关闭全局 Loading。
@MainActor
func hideLoading() {
    LoadingManager.shared.hide()
}
