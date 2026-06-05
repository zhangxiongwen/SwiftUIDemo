//
//  UIApplication+SafeArea.swift
//  SwiftUIDemo
//
//  ActionSheet 贴底时读取 keyWindow 底部安全区
//

import UIKit

extension UIApplication {
    @MainActor
    var keyWindowSafeAreaBottom: CGFloat {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .safeAreaInsets.bottom ?? 0
    }
}
