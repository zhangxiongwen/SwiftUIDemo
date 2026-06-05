//
//  LoadingView.swift
//  SwiftUIDemo
//
//  HUD / Loading
//

import SwiftUI
import UIKit

// MARK: - Metrics

enum LoadingMetrics {
    /// 全屏半透明遮罩（更淡）
    static let scrimOpacity: Double = 0.05

    /// 卡片最小宽度（有文案时随文字变宽，但不小于该值）
    static let boxMinWidth: CGFloat = 80
    /// 卡片最小高度（内容更高时随之增高，但不小于该值）
    static let boxMinHeight: CGFloat = 80
    /// 文案最大排版宽度（仅限制换行，不撑大卡片；短文案仍按实际宽度布局）
    static let boxMaxWidth: CGFloat = 260

    static var messageMaxWidth: CGFloat {
        boxMaxWidth - boxContentPadding * 2
    }

    /// 单行文案宽度（上限 messageMaxWidth），用于在固定宽度内换行。
    static func messageLayoutWidth(for message: String) -> CGFloat {
        guard !message.isEmpty else { return 0 }
        let font = UIFont.preferredFont(forTextStyle: .caption1)
        let rect = (message as NSString).boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: font],
            context: nil
        )
        return min(ceil(rect.width), messageMaxWidth)
    }

    static let boxCornerRadius: CGFloat = 12
    static let boxContentPadding: CGFloat = 12
    static let spinnerSize: CGFloat = 36
    static let messageSpacing: CGFloat = 10

    static let fadeDuration: TimeInterval = 0.22
    static let maxDuration: TimeInterval = 60
}

// MARK: - Host modifier

struct LoadingHostModifier: ViewModifier {
    @Bindable var manager: LoadingManager

    func body(content: Content) -> some View {
        content
            .overlay {
                if manager.isShowing {
                    LoadingView(message: manager.message)
                        .zIndex(101)
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: LoadingMetrics.fadeDuration), value: manager.isShowing)
            .animation(nil, value: manager.message)
    }
}

extension View {
    /// 页面内局部 Loading。全 App 请用根视图 `.appHUDConfig()`。
    func loadingConfig(manager: LoadingManager = .shared) -> some View {
        modifier(LoadingHostModifier(manager: manager))
    }
}

// MARK: - Loading UI

/// 全屏淡遮罩 + 居中黑底白圈 Loading；可用于 `loadingConfig` 或页面内局部叠加。
struct LoadingView: View {
    /// 转圈下方文案；空字符串时仅显示 Progress。
    var message: String = "加载中..."

    var body: some View {
        ZStack {
            // swiftlint:disable:next no_hardcoded_colors
            Color.black.opacity(LoadingMetrics.scrimOpacity)
                .ignoresSafeArea()

            loadingCard
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
    }

    /// 黑底卡片：宽/高均 ≥ 最小值；短文案收窄，长文案在 maxWidth 内换行并撑高背景。
    private var loadingCard: some View {
        VStack(spacing: message.isEmpty ? 0 : LoadingMetrics.messageSpacing) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(LoadingMetrics.spinnerSize / 20)
                .frame(width: LoadingMetrics.spinnerSize, height: LoadingMetrics.spinnerSize)

            if !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
                    .frame(
                        width: LoadingMetrics.messageLayoutWidth(for: message),
                        alignment: .center
                    )
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(LoadingMetrics.boxContentPadding)
        .fixedSize(horizontal: true, vertical: false)
        .frame(
            minWidth: LoadingMetrics.boxMinWidth,
            minHeight: LoadingMetrics.boxMinHeight,
            alignment: .center
        )
        .background(loadingCardBackground)
        // swiftlint:disable:next no_hardcoded_colors
        .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 6)
    }

    private var loadingCardBackground: some View {
        RoundedRectangle(cornerRadius: LoadingMetrics.boxCornerRadius, style: .continuous)
            // swiftlint:disable:next no_hardcoded_colors
            .fill(Color.black.opacity(0.7))
    }
}

/// 兼容旧命名
@available(*, deprecated, renamed: "LoadingView")
typealias LoadingOverlay = LoadingView
