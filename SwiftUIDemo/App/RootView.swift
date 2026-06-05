//
//  RootView.swift
//  SwiftUIDemo
//

import SwiftUI

struct RootView: View {
    @State private var router = AppRouter()

    var body: some View {
        DemoRootView()
            .navigationStackRouter(router: router, routes: AppRouteRegistry.all)
            .environment(router)
            .tint(AppColors.primary)
            .appHUDConfig()
    }
}
