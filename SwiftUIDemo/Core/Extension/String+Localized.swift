//
//  String+Localized.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

extension String {
    // 简易访问器： "login_title".localized
    // 使用 Bundle 查表，兼容 String Catalog 编译出的 Localizable.strings（动态 key 也有效）
    var localized: String {
        let value = Bundle.main.localizedString(forKey: self, value: self, table: "Localizable")
        return value == self ? String(localized: String.LocalizationValue(self)) : value
    }
    
    // 带参数的访问器： "welcome_user".localized(args: "Jack")
    // 注意：这只是简易封装，复杂参数建议直接用 String(localized: ...)
    func localized(args: CVarArg...) -> String {
        return String(format: self.localized, arguments: args)
    }
}
