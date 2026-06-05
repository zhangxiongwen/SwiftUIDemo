//
//  AppActionSheetView.swift
//  SwiftUIDemo
//

import SwiftUI
import UIKit

/// 底部全宽 ActionSheet UI；通常通过 `ViewPresenter.presentActionSheet` 展示。
struct AppActionSheetView: View {
    /// 顶部标题，可为空。
    let title: String?
    /// 顶部说明，可为空。
    let message: String?
    /// 标题区下方的自定义内容（如海报图），可为空。
    let content: AnyView?
    /// 操作项列表（可含 `.cancel`）；点击逻辑写在各 `DialogButton.action` 内。
    let buttons: [DialogButton]

    private var hasHeader: Bool {
        (title?.isEmpty == false) || (message?.isEmpty == false)
    }

    private var hasCustomContent: Bool { content != nil }

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: DialogMetrics.actionSheetTopCornerRadius,
            topTrailingRadius: DialogMetrics.actionSheetTopCornerRadius,
            style: .continuous
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if hasCustomContent, let content {
                content
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
            if (hasHeader || hasCustomContent) && !buttons.isEmpty {
                Divider()
            }
            DialogDividerList(count: buttons.count) { index in
                DialogButtonRow(
                    button: buttons[index],
                    height: DialogMetrics.actionSheetButtonHeight,
                    onTap: buttons[index].action
                )
            }
        }
        .padding(.bottom, bottomSafeAreaInset)
        .frame(maxWidth: .infinity)
        .background {
            Color(uiColor: .secondarySystemBackground).ignoresSafeArea(edges: .bottom)
        }
        .clipShape(panelShape)
    }

    /// 贴底时预留 Home Indicator 区域（UIKit key window safe area）。
    private var bottomSafeAreaInset: CGFloat {
        let scene = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }
            ?? UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let window = scene?.windows.first(where: \.isKeyWindow) ?? scene?.windows.first
        return window?.safeAreaInsets.bottom ?? 0
    }

    @ViewBuilder
    private var header: some View {
        if hasHeader {
            VStack(spacing: 6) {
                if let title, !title.isEmpty {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary)
                }
                if let message, !message.isEmpty {
                    Text(message)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(Color.secondary.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
    }
}
