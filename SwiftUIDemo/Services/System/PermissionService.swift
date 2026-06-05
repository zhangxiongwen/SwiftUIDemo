//
//  PermissionService.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation
import AVFoundation
import Photos
import UserNotifications
import UIKit

enum PermissionType {
    case camera
    case photoLibrary
    case notification
}

enum PermissionStatus {
    case notDetermined
    case authorized
    case denied
}

class PermissionService {
    
    // 检查当前权限状态
    static func checkStatus(_ type: PermissionType) -> PermissionStatus {
        switch type {
        case .camera:
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            return mapAVStatus(status)
        case .photoLibrary:
            let status = PHPhotoLibrary.authorizationStatus()
            return mapPhotoStatus(status)
        case .notification:
            // 通知比较特殊，通常异步获取，这里简化处理，实际需异步
            return .notDetermined
        }
    }
    
    // 请求权限 (异步)
    static func request(_ type: PermissionType) async -> Bool {
        switch type {
        case .camera:
            return await AVCaptureDevice.requestAccess(for: .video)
            
        case .photoLibrary:
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return status == .authorized || status == .limited
            
        case .notification:
            let center = UNUserNotificationCenter.current()
            do {
                let granted = try await center.requestAuthorization(options: [.sound, .badge])
                return granted
            } catch {
                return false
            }
        }
    }
    
    // 辅助：跳转系统设置页
    static func openSystemSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    // MARK: - Private Helpers
    private static func mapAVStatus(_ status: AVAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
    
    private static func mapPhotoStatus(_ status: PHAuthorizationStatus) -> PermissionStatus {
        switch status {
        case .authorized, .limited: return .authorized
        case .denied, .restricted: return .denied
        case .notDetermined: return .notDetermined
        @unknown default: return .denied
        }
    }
}
