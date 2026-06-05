//
//  AppRouter.swift
//  SwiftUIDemo
//
//  全局导航：NavigationStack push / pop / pushPath。
//  弹窗与整页 present 请使用 ViewPresenter（每页 @State + .viewPresenter，与 Router 无关）。
//

import SwiftUI

// MARK: - AppRouter

/// 全局路由对象，由根视图创建并通过 `@Environment` 注入子树。
@Observable
final class AppRouter {

    /// NavigationStack 的 push 路径。
    var path = NavigationPath()

    /// 已注册路由的路径解析表（由 `navigationStackRouter` 填充）。
    let routePathRegistry = RoutePathRegistry()

    var hasPushedPages: Bool { !path.isEmpty }

    /// 当前 NavigationStack 已 push 的页面层数（不含栈根视图）。
    var pushDepth: Int { path.count }

    // MARK: Push

    /// 压入路径路由 + 可选 query / extra。
    func push<R: AppPathRoute>(
        _ route: R,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        path.append(RoutePush(route, query: query, extra: extra))
    }

    /// 字符串跳转：rawValue 根路径 + 路径内 query，再合并入参 query / extra。
    func pushPath(
        _ pathString: String,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        let trimmed = PathParser.trim(pathString)
        if !routePathRegistry.push(trimmed, onto: &path, query: query, extra: extra) {
            path.append(RouteNotFound(requestedPath: trimmed))
        }
    }

    // MARK: Pop

    /// 弹出导航栈顶一页。
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }

    /// 连续后退多页；`steps <= 0` 无操作，超出当前深度时只退到栈根。
    func pop(steps: Int) {
        guard steps > 0 else { return }
        let count = min(steps, path.count)
        for _ in 0..<count {
            path.removeLast()
        }
    }

    /// 清空全部 push 页面，回到 NavigationStack 栈根。
    func popToRoot() {
        path = NavigationPath()
    }
}

// MARK: - RoutePush

/// 导航栈条目：路由枚举 + query 字典 + extra 对象。
struct RoutePush<R: Hashable>: Hashable {
    let route: R
    var query: [String: String]
    var extra: AnyHashable?

    init(_ route: R, query: [String: String] = [:], extra: (any Hashable)? = nil) {
        self.route = route
        self.query = query
        self.extra = extra.map { AnyHashable($0) }
    }

    func merging(query extraQuery: [String: String], extra object: (any Hashable)?) -> RoutePush<R> {
        var copy = self
        for (key, value) in extraQuery {
            copy.query[key] = value
        }
        if let object {
            copy.extra = AnyHashable(object)
        }
        return copy
    }
}

// MARK: - PathParser

enum PathParser {

    static func trim(_ path: String) -> String {
        path.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func root(from path: String) -> String {
        let s = trim(path)
        guard let i = s.firstIndex(of: "?") else { return s }
        return String(s[..<i])
    }

    static func query(from path: String) -> [String: String] {
        let s = trim(path)
        guard let i = s.firstIndex(of: "?") else { return [:] }
        let q = String(s[s.index(after: i)...])
        var result: [String: String] = [:]
        for pair in q.split(separator: "&") {
            let parts = pair.split(separator: "=", maxSplits: 1).map(String.init)
            guard let key = parts.first, !key.isEmpty else { continue }
            let raw = parts.count > 1 ? parts[1] : ""
            result[key] = raw.removingPercentEncoding ?? raw
        }
        return result
    }
}

// MARK: - RoutePathRegistry

/// 注册各模块的 `AppPathRoute`（路径 rawValue + query），供 `router.pushPath` 使用。
final class RoutePathRegistry {

    private var handlers: [(
        inout NavigationPath,
        String,
        [String: String],
        (any Hashable)?
    ) -> Bool] = []

    func reset() { handlers.removeAll() }

    func register<R: AppPathRoute>(_ type: R.Type) {
        handlers.append { path, pathString, extraQuery, extra in
            let trimmed = PathParser.trim(pathString)
            let root = PathParser.root(from: trimmed)
            guard let route = R(rawValue: root) else { return false }
            let pathQuery = PathParser.query(from: trimmed)
            let push = RoutePush(route, query: pathQuery)
                .merging(query: extraQuery, extra: extra)
            path.append(push)
            return true
        }
    }

    @discardableResult
    func push(
        _ path: String,
        onto navigationPath: inout NavigationPath,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) -> Bool {
        let trimmed = PathParser.trim(path)
        for handler in handlers {
            if handler(&navigationPath, trimmed, query, extra) { return true }
        }
        return false
    }
}
