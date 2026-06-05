//
//  AppLogger.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation
import OSLog

struct AppLogger {
    // 定义子系统，方便在 Mac 的“控制台”应用中筛选
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.template.app"
    
    // 不同模块的日志分类
    static let network = Logger(subsystem: subsystem, category: "Networking")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let database = Logger(subsystem: subsystem, category: "Database")
    
    // 封装一个简单的 debug 方法
    static func debug(_ message: String) {
        #if DEBUG
        print("🔍 [DEBUG]: \(message)")
        #endif
    }
    
    static func error(_ message: String) {
        print("❌ [ERROR]: \(message)")
        // 这里以后可以接入 Firebase Crashlytics 等上报工具
    }
}
