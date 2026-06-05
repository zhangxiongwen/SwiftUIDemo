//
//  ToastManager.swift
//  SwiftUIDemo
//
//  HUD / Toast
//
//  全局 Toast 状态；根视图 `.appHUDConfig()` + 任意处 `showToast(_:)`。
//

import SwiftUI

/// Toast 在屏幕上的垂直位置。
enum ToastPosition: Sendable {
    case top
    case center
    case bottom
}

/// 全局 Toast 单例状态机，由 `ToastHostModifier` 订阅并渲染。
@Observable
class ToastManager {
    static let shared = ToastManager()

    /// 是否正在展示 Toast。
    var isShowing: Bool = false
    /// 当前文案。
    var message: String = ""
    /// 当前展示位置。
    var position: ToastPosition = .center

    private var workItem: DispatchWorkItem?

    private init() {}

    /// 显示 Toast；若已有 Toast 则无动画替换文案与位置。
    /// - Parameters:
    ///   - message: 提示文案。
    ///   - position: 展示位置，默认居中。
    ///   - duration: 自动消失秒数，默认 2s。
    func show(
        _ message: String,
        position: ToastPosition = .center,
        duration: TimeInterval = 2.0
    ) {
        workItem?.cancel()

        let replacing = isShowing
        if replacing {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                self.message = message
                self.position = position
                self.isShowing = true
            }
        } else {
            withAnimation(.easeInOut(duration: ToastMetrics.fadeDuration)) {
                self.message = message
                self.position = position
                self.isShowing = true
            }
        }

        HapticService.selection()
        scheduleAutoDismiss(after: duration)
    }

    private func scheduleAutoDismiss(after duration: TimeInterval) {
        let task = DispatchWorkItem { [weak self] in
            guard let self else { return }
            withAnimation(.easeInOut(duration: ToastMetrics.fadeDuration)) {
                self.isShowing = false
            }
        }
        workItem = task
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: task)
    }
}

/// 显示全局 Toast（需根视图已调用 `.appHUDConfig()`）。
@MainActor
func showToast(
    _ message: String,
    position: ToastPosition = .center,
    duration: TimeInterval = 2.0
) {
    ToastManager.shared.show(message, position: position, duration: duration)
}
