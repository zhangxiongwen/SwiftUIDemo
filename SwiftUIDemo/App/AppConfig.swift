//
//  AppConfig.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// 1. 定义环境类型
enum AppEnvironment {
    case debug
    case production
    
    // 根据环境返回对应的 Base URL
    var baseURL: String {
        switch self {
        case .debug:
            return "http://127.0.0.1:8000"
        case .production:
            return "https://api.your-production-server.com"
        }
    }
}

// 2. 配置管理器
struct AppConfig {
    // 自动检测当前编译模式
    static var current: AppEnvironment {
        #if DEBUG
        return .debug
        #else
        return .production
        #endif
    }
    
    // ✨ 新增：是否开启 Mock 模式
    // 改为 true，App 所有的接口都会走本地假数据
    static let useMock: Bool = true
    
    // 全局常量
    static let timeoutInterval: TimeInterval = 30.0
}
