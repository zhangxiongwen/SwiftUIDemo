//
//  ToastView.swift
//  SwiftUIDemo
//
//  HUD / Toast
//

import SwiftUI
import UIKit

// MARK: - Metrics

enum ToastMetrics {
    static let contentHorizontalPadding: CGFloat = 10
    static let contentVerticalPadding: CGFloat = 6
    static let cornerRadius: CGFloat = 8
    static let backgroundOpacity: Double = 0.85
    static let fadeDuration: TimeInterval = 0.22

    static var maxContentWidth: CGFloat {
        let screenWidth = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.screen.bounds.width ?? 390
        return min(screenWidth * 0.75, 280)
    }
}

// MARK: - Host modifier

struct ToastHostModifier: ViewModifier {
    @Bindable var manager: ToastManager

    func body(content: Content) -> some View {
        content
            .overlay {
                if manager.isShowing {
                    toastOverlay
                        .zIndex(100)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: ToastMetrics.fadeDuration), value: manager.isShowing)
    }

    @ViewBuilder
    private var toastOverlay: some View {
        ZStack {
            switch manager.position {
            case .top:
                VStack {
                    ToastView(message: manager.message)
                        .padding(.top, 12)
                    Spacer(minLength: 0)
                }

            case .center:
                ToastView(message: manager.message)

            case .bottom:
                VStack {
                    Spacer(minLength: 0)
                    ToastView(message: manager.message)
                        .padding(.bottom, 24)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .allowsHitTesting(false)
        .animation(nil, value: manager.message)
        .animation(nil, value: manager.position)
    }
}

extension View {
    /// 页面内局部 Toast。全 App 请用根视图 `.appHUDConfig()`。
    func toastConfig(manager: ToastManager = .shared) -> some View {
        modifier(ToastHostModifier(manager: manager))
    }

    /// 兼容旧命名
    @available(*, deprecated, renamed: "toastConfig(manager:)")
    func toastHost(manager: ToastManager = .shared) -> some View {
        toastConfig(manager: manager)
    }
}

// MARK: - Toast view

/// 黑底白字 Toast 气泡；短文案单行自适应宽度，长文案自动换行。
struct ToastView: View {
    /// 展示文案。
    let message: String

    var body: some View {
        ViewThatFits(in: .horizontal) {
            toastText(lineLimit: 1)
                .fixedSize(horizontal: true, vertical: false)

            toastText(lineLimit: nil)
                .frame(maxWidth: ToastMetrics.maxContentWidth)
        }
    }

    private func toastText(lineLimit: Int?) -> some View {
        Text(message)
            .font(.body)
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .lineSpacing(2)
            .lineLimit(lineLimit)
            .padding(.horizontal, ToastMetrics.contentHorizontalPadding)
            .padding(.vertical, ToastMetrics.contentVerticalPadding)
            .background {
                RoundedRectangle(cornerRadius: ToastMetrics.cornerRadius, style: .continuous)
                    // swiftlint:disable:next no_hardcoded_colors
                    .fill(Color.black.opacity(ToastMetrics.backgroundOpacity))
            }
            // swiftlint:disable:next no_hardcoded_colors
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}
