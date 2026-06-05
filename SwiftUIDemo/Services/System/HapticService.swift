//
//  HapticService.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import UIKit

struct HapticService {
    // 成功/失败/警告 (Notification)
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
    
    // 轻/中/重 撞击 (Impact)
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    // 选择滚轮 (Selection)
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}
