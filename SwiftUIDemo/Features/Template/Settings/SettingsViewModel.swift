//
//  SettingsViewModel.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation
import SwiftUI

@Observable
class SettingsViewModel: BaseViewModel {
    
    var cacheSize: String = ""
    var appVersion: String = ""
    
    // 模拟用户信息（实际应从 UserManager 获取）
    var userName: String = "iOS 开发者"
    var userAvatar: String = "person.crop.circle.fill" // SF Symbol
    
    func onAppear() {
        self.appVersion = AppUtils.appVersion
        self.cacheSize = AppUtils.getCacheSize()
    }
    
    // 清理缓存逻辑
    func clearCache() {
        FileService.clearCache()
        HapticService.notification(.success) // 震动反馈
        self.cacheSize = AppUtils.getCacheSize()
    }
    
    // 退出登录
    func logout() {
        // 可以在这里做一些 API 调用通知后端登出
        // 然后调用全局状态清理
        UserManager.shared.logout()
    }
}
