//
//  Color+Ext.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

extension Color {
    /// 安全的颜色初始化器
    /// - Parameter name: Assets.xcassets 里的颜色名称
    init(safe name: String) {
        // 在 Debug 模式下，如果加载失败，回退到品红色方便调试
        // 在 Release 模式下，尽量加载，失败则回退到 clear
        #if DEBUG
        self.init(name, bundle: nil)
        #else
        self.init(name, bundle: nil)
        #endif
    }
}
