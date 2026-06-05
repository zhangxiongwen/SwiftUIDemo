//
//  TemplateRoute.swift
//  SwiftUIDemo
//
//  模版模块路由：统一 AppPathRoute，参数走 query。
//

import SwiftUI

enum TemplateRoute: String, AppPathRoute {
    case homeDetail = "/template/homeDetail"
    case homeBanner = "/template/homeBanner"
    case profile = "/template/profile"
    case about = "/template/about"
    case webView = "/template/webView"
}

extension TemplateRoute {
    @ViewBuilder
    static func view(for push: RoutePush<TemplateRoute>) -> some View {
        switch push.route {
        case .homeDetail:
            let id = Int(push.query["id"] ?? "") ?? 0
            Text("详情页 ID: \(id)")
                .appFont(AppFonts.h1)
                .baseNavigationBar(title: "详情")

        case .homeBanner:
            let url = push.query["url"] ?? ""
            WebViewContainer(urlString: url)
                .baseNavigationBar(title: "活动详情")

        case .profile:
            Text("个人资料页")
                .padding()
                .baseNavigationBar(title: "个人资料")

        case .about:
            Text("关于我们")
                .padding()
                .baseNavigationBar(title: "关于我们")

        case .webView:
            let url = push.query["url"] ?? ""
            let title = push.query["title"] ?? ""
            WebViewContainer(urlString: url)
                .baseNavigationBar(title: title)
        }
    }
}
