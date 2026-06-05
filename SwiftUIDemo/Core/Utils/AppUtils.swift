//
//  AppUtils.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

struct AppUtils {
    static var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
    
    static func getCacheSize() -> String {
        return FileService.getCacheSizeString()
    }
}
