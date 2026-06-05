//
//  TokenManager.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

class TokenManager {
    static let shared = TokenManager()
    
    private let tokenKey = "auth_token"
    
    // 保存 Token
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
        AppLogger.database.debug("Token 已保存")
    }
    
    // 获取 Token
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    // 清除 Token (退出登录用)
    func clearToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
        AppLogger.database.debug("Token 已清除")
    }
    
    // 判断是否登录
    var hasToken: Bool {
        return getToken() != nil
    }
}
