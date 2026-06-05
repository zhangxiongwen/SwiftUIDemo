//
//  HUDInstaller.swift
//  SwiftUIDemo
//
//  HUD 模块入口：Toast + Loading 统一挂在独立 UIWindow。
//  根视图 `.appHUDConfig()` 一次即可；同目录还有 ToastManager / LoadingManager。
//

import SwiftUI
import UIKit

// MARK: - 安装（根视图调用一次）

private struct InstallHUDModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear {
                HUDWindow.shared.installIfNeeded()
            }
    }
}

extension View {
    /// Toast + Loading 全局 HUD。在 `RootView` 调用一次即可，present 内直接 `showToast` / `showLoading`。
    func appHUDConfig() -> some View {
        modifier(InstallHUDModifier())
    }
}

// MARK: - HUD Window

@MainActor
private final class HUDWindow {
    static let shared = HUDWindow()

    private var hudWindow: PassThroughWindow?

    private init() {}

    func installIfNeeded() {
        guard hudWindow == nil else { return }
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }

        let window = PassThroughWindow(windowScene: scene)
        window.windowLevel = .statusBar + 1
        window.backgroundColor = .clear

        let host = UIHostingController(rootView: HUDContentView())
        host.view.backgroundColor = .clear
        window.rootViewController = host
        window.isHidden = false

        hudWindow = window
    }
}

/// 触摸穿透：无 Loading 时事件交给下层 Window；Loading 展示时由 HUD 拦截。
private final class PassThroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard let hit = super.hitTest(point, with: event) else { return nil }
        if LoadingManager.shared.isShowing {
            return hit
        }
        if hit === self || hit === rootViewController?.view {
            return nil
        }
        return hit
    }
}

// MARK: - HUD 内容

private struct HUDContentView: View {
    @Bindable private var toastManager = ToastManager.shared
    @Bindable private var loadingManager = LoadingManager.shared

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .overlay { toastLayer }
            .overlay { loadingLayer }
            .animation(.easeInOut(duration: ToastMetrics.fadeDuration), value: toastManager.isShowing)
            .animation(.easeInOut(duration: LoadingMetrics.fadeDuration), value: loadingManager.isShowing)
            .animation(nil, value: toastManager.message)
            .animation(nil, value: loadingManager.message)
    }

    @ViewBuilder
    private var toastLayer: some View {
        if toastManager.isShowing {
            ZStack {
                switch toastManager.position {
                case .top:
                    VStack {
                        ToastView(message: toastManager.message)
                            .padding(.top, 12)
                        Spacer(minLength: 0)
                    }
                case .center:
                    ToastView(message: toastManager.message)
                case .bottom:
                    VStack {
                        Spacer(minLength: 0)
                        ToastView(message: toastManager.message)
                            .padding(.bottom, 24)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .allowsHitTesting(false)
            .transition(.opacity)
        }
    }

    @ViewBuilder
    private var loadingLayer: some View {
        if loadingManager.isShowing {
            LoadingView(message: loadingManager.message)
                .transition(.opacity)
        }
    }
}
