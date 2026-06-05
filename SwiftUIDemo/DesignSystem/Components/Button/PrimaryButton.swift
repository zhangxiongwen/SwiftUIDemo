//
//  PrimaryButton.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

/// 全宽主按钮；支持加载中与禁用态（与全局 `showLoading` 无关，仅按钮内转圈）。
struct PrimaryButton: View {
    /// 按钮标题；`isLoading` 为 true 时不显示。
    let title: String
    /// 为 true 时显示按钮内 Progress 并禁止点击。
    var isLoading: Bool = false
    /// 为 true 时灰色背景并禁止点击。
    var isDisabled: Bool = false
    /// 点击回调。
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                if isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(title)
                        .appFont(AppFonts.body)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isDisabled ? AppColors.textSecondary.opacity(0.5) : AppColors.primary)
            // swiftlint:disable:next no_hardcoded_colors
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(isLoading || isDisabled)
    }
}
