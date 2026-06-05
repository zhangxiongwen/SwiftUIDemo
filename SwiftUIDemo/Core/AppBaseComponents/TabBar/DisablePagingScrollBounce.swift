//
//  DisablePagingScrollBounce.swift
//  SwiftUIDemo
//

import SwiftUI
import UIKit

extension View {
    /// 关闭 `TabView(.page)` 内部分页 ScrollView 的橡皮筋回弹（不影响普通 `ScrollView`）。
    func disablePageTabViewBounce() -> some View {
        overlay(DisablePagingScrollBounceRepresentable())
    }

    /// 禁用 PageTabViewStyle 左右滑动（仍可通过 selection 编程切换）
    func disablePageTabViewSwipe() -> some View {
        overlay(DisablePagingScrollSwipeRepresentable())
    }
}

private struct DisablePagingScrollBounceRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // 延迟到下一轮 runloop，确保 TabView 的 UIKit 视图树已创建完成
        DispatchQueue.main.async {
            guard let scrollView = uiView.findNearestPagingScrollView() else { return }
            scrollView.bounces = false
            scrollView.alwaysBounceHorizontal = false
            scrollView.alwaysBounceVertical = false
        }
    }
}

private struct DisablePagingScrollSwipeRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        view.isUserInteractionEnabled = false
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = uiView.findNearestPagingScrollView() else { return }
            scrollView.isScrollEnabled = false
        }
    }
}

private extension UIView {
    /// 从当前 view 向上找，再向下遍历，定位到 `isPagingEnabled == true` 的 UIScrollView
    func findNearestPagingScrollView() -> UIScrollView? {
        var node: UIView? = self
        for _ in 0..<12 { // 防止无限向上
            if let found = node?.findPagingScrollViewInSubtree() { return found }
            node = node?.superview
        }
        return nil
    }

    func findPagingScrollViewInSubtree() -> UIScrollView? {
        if let scroll = self as? UIScrollView, scroll.isPagingEnabled {
            return scroll
        }
        for sub in subviews {
            if let found = sub.findPagingScrollViewInSubtree() { return found }
        }
        return nil
    }
}

