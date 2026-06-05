//
//  AppRoute.swift
//  SwiftUIDemo
//

import SwiftUI

// MARK: - Navigation 环境

private enum IsNavigationDestinationKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    var isNavigationDestination: Bool {
        get { self[IsNavigationDestinationKey.self] }
        set { self[IsNavigationDestinationKey.self] = newValue }
    }
}

// MARK: - 路由协议

/// 路径路由：全 App 统一使用此协议。
///
/// - `rawValue`：以 `/` 开头的路径（如 `"/toastDemo"`）
/// - 栈条目：`RoutePush<Self>`，支持 `query` / `extra`
/// - 跳转：`push(_:query:extra:)`、`pushPath(_:query:extra:)`
protocol AppPathRoute: Hashable, RawRepresentable where RawValue == String {
    associatedtype Body: View
    @ViewBuilder
    static func view(for push: RoutePush<Self>) -> Body
}

// MARK: - 注册

struct RouteRegistration {
    private let apply: (AnyView) -> AnyView
    private let registerPath: (RoutePathRegistry) -> Void

    init<R: AppPathRoute>(_ routeType: R.Type) {
        registerPath = { $0.register(R.self) }
        apply = Self.makePathRouteApply(routeType)
    }

    func apply(to view: AnyView) -> AnyView { apply(view) }
    func registerPath(in registry: RoutePathRegistry) { registerPath(registry) }

    private static func makePathRouteApply<R: AppPathRoute>(_ routeType: R.Type) -> (AnyView) -> AnyView {
        { content in
            AnyView(
                content.navigationDestination(for: RoutePush<R>.self) { push in
                    R.view(for: push)
                        .environment(\.isNavigationDestination, true)
                }
            )
        }
    }
}

@resultBuilder
enum AppRouteBuilder {
    static func buildBlock(_ registrations: RouteRegistration...) -> [RouteRegistration] {
        Array(registrations)
    }
    static func buildExpression<R: AppPathRoute>(_ routeType: R.Type) -> RouteRegistration {
        RouteRegistration(routeType)
    }
    static func buildArray(_ registrations: [[RouteRegistration]]) -> [RouteRegistration] {
        registrations.flatMap { $0 }
    }
}

// MARK: - NavigationStack

extension View {
    func baseRouter(@AppRouteBuilder _ routes: () -> [RouteRegistration]) -> some View {
        let registrations = routes()
        return registrations.reduce(AnyView(self)) { view, registration in
            registration.apply(to: view)
        }
    }

    func navigationStackRouter(
        router: AppRouter,
        @AppRouteBuilder routes: () -> [RouteRegistration]
    ) -> some View {
        let registrations = routes()
        router.routePathRegistry.reset()
        registrations.forEach { $0.registerPath(in: router.routePathRegistry) }

        return NavigationStack(path: Bindable(router).path) {
            registrations.reduce(AnyView(self)) { view, registration in
                registration.apply(to: view)
            }
            .routeNotFoundDestination()
        }
    }
}

// MARK: - 404

/// 字符串路径无法解析时 push 的占位路由。
struct RouteNotFound: Hashable {
    let requestedPath: String
}

struct RouteNotFoundView: View {
    let requestedPath: String

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 56))
                .foregroundStyle(Color.secondary)

            Text("404")
                .font(.largeTitle.bold())
                .foregroundStyle(Color.primary)

            Text("未找到对应页面")
                .font(.body)
                .foregroundStyle(Color.secondary)

            Text(requestedPath)
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(uiColor: .systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text("请检查路径是否已在根视图 `navigationStackRouter` 中注册。")
                .font(.caption)
                .foregroundStyle(Color.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(uiColor: .secondarySystemBackground))
        .baseNavigationBar(title: "页面不存在")
    }
}

extension View {
    func routeNotFoundDestination() -> some View {
        navigationDestination(for: RouteNotFound.self) { item in
            RouteNotFoundView(requestedPath: item.requestedPath)
                .environment(\.isNavigationDestination, true)
        }
    }
}
