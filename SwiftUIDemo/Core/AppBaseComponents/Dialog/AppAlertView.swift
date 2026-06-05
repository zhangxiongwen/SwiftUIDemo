//
//  AppAlertView.swift
//  SwiftUIDemo
//

import SwiftUI

/// 居中 Alert 卡片 UI；通常通过 `ViewPresenter.presentAlert` 展示。
/// - Note: ≤2 个按钮横向排列，>2 个纵向排列；点击逻辑写在各 `DialogButton.action` 内。
struct AppAlertView: View {
    /// 标题，可为空。
    let title: String?
    /// 说明文案，可为空。
    let message: String?
    /// 标题与按钮之间的自定义区域，可为空。
    let content: AnyView?
    /// 底部操作按钮列表。
    let buttons: [DialogButton]

    private var hasBody: Bool {
        message != nil || content != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if hasBody { bodyContent }
            Divider()
            buttonsView
        }
        .frame(width: DialogMetrics.alertWidth)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: DialogMetrics.alertCornerRadius, style: .continuous))
        .shadow(color: .black.opacity(0.18), radius: 24, y: 8)
    }

    @ViewBuilder
    private var header: some View {
        if let title, !title.isEmpty {
            Text(title)
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.primary)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, hasBody ? 8 : 16)
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        VStack(spacing: 12) {
            if let message, !message.isEmpty {
                Text(message)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let content { content }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var buttonsView: some View {
        let height = DialogMetrics.alertButtonHeight
        if buttons.count <= 2 {
            HStack(spacing: 0) {
                ForEach(Array(buttons.enumerated()), id: \.element.id) { index, button in
                    if index > 0 { Divider() }
                    DialogButtonRow(
                        button: button,
                        height: height,
                        onTap: button.action
                    )
                }
            }
            .frame(height: height)
        } else {
            DialogDividerList(count: buttons.count) { index in
                DialogButtonRow(
                    button: buttons[index],
                    height: height,
                    onTap: buttons[index].action
                )
            }
        }
    }
}
