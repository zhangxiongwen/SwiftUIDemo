//
//  CombinePage.swift
//  SwiftUIDemo
//
//  Combine 响应式编程教程目录页。
//

import SwiftUI

struct CombinePage: View {
    @State private var navigator = Navigator()

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Apple 官方的响应式编程框架")
                        .appFont(AppFonts.h2)
                    Text("Combine 用「发布者 → 操作符 → 订阅者」的方式处理异步事件流。建议先阅读使用文档，再配合下方演示动手练习。")
                        .appFont(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }
                .padding(.vertical, 4)
            }

            Section("学习资料") {
                CombineCatalogRow(
                    title: "使用文档",
                    subtitle: "由浅入深 · 概念 · 用法 · 代码 · SwiftUI 实战",
                    icon: "doc.text.fill",
                    level: "推荐"
                ) {
                    navigator.push(CombineRoute.guide)
                }
            }

            Section("入门") {
                catalogRow(
                    title: "核心概念",
                    subtitle: "Publisher · Subscriber · Operator · Cancellable",
                    icon: "book.fill",
                    level: "基础",
                    route: .intro
                )
                catalogRow(
                    title: "基础发布者",
                    subtitle: "Just · Empty · Fail · Future · Deferred",
                    icon: "paperplane.fill",
                    level: "基础",
                    route: .publishers
                )
                catalogRow(
                    title: "Subject 主题",
                    subtitle: "PassthroughSubject · CurrentValueSubject",
                    icon: "antenna.radiowaves.left.and.right",
                    level: "基础",
                    route: .subjects
                )
            }

            Section("操作符") {
                catalogRow(
                    title: "变换与过滤",
                    subtitle: "map · filter · compactMap · scan · removeDuplicates",
                    icon: "arrow.triangle.branch",
                    level: "进阶",
                    route: .operators
                )
                catalogRow(
                    title: "组合多个流",
                    subtitle: "combineLatest · merge · zip",
                    icon: "arrow.triangle.merge",
                    level: "进阶",
                    route: .combining
                )
                catalogRow(
                    title: "错误处理",
                    subtitle: "catch · retry · replaceError · mapError",
                    icon: "exclamationmark.shield.fill",
                    level: "进阶",
                    route: .errorHandling
                )
                catalogRow(
                    title: "线程调度",
                    subtitle: "subscribe(on:) · receive(on:) · 主线程更新 UI",
                    icon: "cpu",
                    level: "进阶",
                    route: .scheduling
                )
            }

            Section("实战") {
                catalogRow(
                    title: "SwiftUI 集成",
                    subtitle: "@Published · ObservableObject · assign(to:)",
                    icon: "swift",
                    level: "实战",
                    route: .swiftUI
                )
                catalogRow(
                    title: "综合案例",
                    subtitle: "搜索防抖 · 表单验证 · 网络请求链",
                    icon: "hammer.fill",
                    level: "实战",
                    route: .practical
                )
            }
        }
        .baseNavigationBar(title: "Combine")
        .navigator(navigator)
    }

    private func catalogRow(
        title: String,
        subtitle: String,
        icon: String,
        level: String,
        route: CombineRoute
    ) -> some View {
        CombineCatalogRow(
            title: title,
            subtitle: subtitle,
            icon: icon,
            level: level
        ) {
            navigator.push(route)
        }
    }
}
