//
//  UserManager.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation
import SwiftUI

@Observable
class UserManager {
    // 单例模式，方便全局访问
    static let shared = UserManager()
    
    // 核心状态：是否已登录
    // 当这个属性改变时，SwiftUI 根视图会自动刷新
    var isLoggedIn: Bool = false
    
    // 当前用户信息 (可选，登录后获取)
    // var currentUser: User?
    
    private init() {
        // 初始化时检查本地有没有 Token
        self.isLoggedIn = TokenManager.shared.hasToken
    }
    
    // 登录动作 (通常由 LoginViewModel 调用)
    func login(token: String) {
        TokenManager.shared.saveToken(token)
        self.isLoggedIn = true
        // 这里以后可以触发获取用户详情的接口
    }
    
    // 登出动作 (通常由 设置页 或 401错误 触发)
    func logout() {
        TokenManager.shared.clearToken()
        self.isLoggedIn = false
        // 清理其他缓存...
    }
}
