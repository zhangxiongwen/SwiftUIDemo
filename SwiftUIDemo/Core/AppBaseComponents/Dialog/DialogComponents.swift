//
//  DialogComponents.swift
//  SwiftUIDemo
//
//  Dialog 按钮模型、尺寸常量与共用 UI 片段
//

import SwiftUI

// MARK: - Button model

/// Dialog 按钮视觉样式（由 `DialogButtonRow` 统一渲染）。
enum DialogButtonStyle {
    case `default`
    case cancel
    case destructive

    var foregroundColor: Color {
        switch self {
        case .default, .cancel: Color.accentColor
        case .destructive: Color.red
        }
    }

    var fontWeight: Font.Weight {
        switch self {
        case .default, .destructive: .semibold
        case .cancel: .regular
        }
    }
}

/// Alert / ActionSheet 按钮数据；点击时执行 `action`（关闭弹窗请用 `presenter.dismiss(complete:)`，或使用 `presentCommonAlert`）。
struct DialogButton: Identifiable {
    let id = UUID()
    let title: String
    let style: DialogButtonStyle
    let action: () -> Void

    /// 取消样式按钮，默认标题「取消」。
    static func cancel(
        _ title: String = "取消",
        action: @escaping () -> Void = {}
    ) -> DialogButton {
        DialogButton(title: title, style: .cancel, action: action)
    }

    /// 危险操作样式（红色）。
    static func destructive(
        _ title: String,
        action: @escaping () -> Void = {}
    ) -> DialogButton {
        DialogButton(title: title, style: .destructive, action: action)
    }

    /// 主操作样式（主题色、半粗体）。
    static func `default`(
        _ title: String,
        action: @escaping () -> Void = {}
    ) -> DialogButton {
        DialogButton(title: title, style: .default, action: action)
    }
}

// MARK: - Metrics

enum DialogMetrics {
    static let scrimOpacity: Double = 0.32

    static let alertWidth: CGFloat = 270
    static let alertCornerRadius: CGFloat = 14
    static let alertButtonHeight: CGFloat = 48

    static let actionSheetTopCornerRadius: CGFloat = 16
    static let actionSheetButtonHeight: CGFloat = 56

    static let dialogAnimationDuration: Double = 0.25
    static let alertAnimation: Animation = .easeOut(duration: dialogAnimationDuration)
    static let actionSheetAnimation: Animation = .easeInOut(duration: dialogAnimationDuration)
    static let scrimAnimation: Animation = .easeOut(duration: dialogAnimationDuration)
    static let contentAnimationDuration: Duration = .milliseconds(250)

    /// 整页 presentPage / presentNavigationPage 使用的系统 fullScreenCover 转场。
    static let pagePresentationAnimation: Animation = .easeInOut(duration: 0.35)
    static let pagePresentationDuration: Duration = .milliseconds(350)

    /// 关闭系统 present 转场，仅保留 Dialog 内部自定义动画。
    static func withoutSystemPresentationAnimation(_ action: () -> Void) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction, action)
    }
}

// MARK: - Building blocks

/// 纵向按钮列表，项之间用 Divider 分隔
struct DialogDividerList<Content: View>: View {
    let count: Int
    @ViewBuilder let row: (Int) -> Content

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0 ..< count, id: \.self) { index in
                if index > 0 { Divider() }
                row(index)
            }
        }
    }
}

/// 单行 Dialog 按钮（全宽、固定高度）。
struct DialogButtonRow: View {
    let button: DialogButton
    let height: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Text(button.title)
                .font(.body)
                .fontWeight(button.style.fontWeight)
                .foregroundStyle(button.style.foregroundColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
