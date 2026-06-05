//
//  AppFonts.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

struct AppFonts {
    static func h1() -> Font {
        return .system(size: 24, weight: .bold)
    }
    
    static func h2() -> Font {
        return .system(size: 20, weight: .semibold)
    }
    
    static func body() -> Font {
        return .system(size: 16, weight: .regular)
    }
    
    static func caption() -> Font {
        return .system(size: 14, weight: .regular)
    }
}

// 方便使用：Text("Hello").appFont(.h1)
extension View {
    func appFont(_ fontProvider: () -> Font) -> some View {
        self.font(fontProvider())
    }
}
