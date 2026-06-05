//
//  AppRouteRegistry.swift
//  SwiftUIDemo
//
//  全量路由注册：根 NavigationStack 与 presentNavigationPage 共用。
//

import SwiftUI

enum AppRouteRegistry {
    @AppRouteBuilder
    static func all() -> [RouteRegistration] {
        CustomViewsRoute.self
        TemplateRoute.self
    }
}

