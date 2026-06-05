//
//  WebViewContainer.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI
import WebKit

struct WebViewContainer: UIViewRepresentable {
    let urlString: String
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            let request = URLRequest(url: url)
            uiView.load(request)
        }
    }
}

// 包装一个带导航栏的视图，给 Router 使用
struct GenericWebView: View {
    let url: String
    let title: String
    
    var body: some View {
        WebViewContainer(urlString: url)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
    }
}
