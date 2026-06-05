//
//  HomeViewModel.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import Foundation

// 简单的 Banner 模型
struct BannerItem: Identifiable {
    let id = UUID()
    let color: String // 模拟图片颜色
    let title: String
    let url: String
}

// 简单的动态模型
struct FeedItem: Identifiable {
    let id: Int
    let title: String
    let desc: String
    let time: String
}

@Observable
class HomeViewModel: BaseViewModel {
    
    var banners: [BannerItem] = []
    var feeds: [FeedItem] = []
    
    // 模拟网络请求
    func fetchData() async {
        if banners.isEmpty { startLoading() }
        
        // 模拟延迟
        try? await Task.sleep(nanoseconds: 1 * 500_000_000) // 0.5s
        
        await MainActor.run {
            // 1. 生成 Mock Banners
            self.banners = [
                BannerItem(color: "blue", title: "新版本发布", url: "https://apple.com"),
                BannerItem(color: "orange", title: "限时活动", url: "https://google.com"),
                BannerItem(color: "pink", title: "会员福利", url: "https://bing.com")
            ]
            
            // 2. 生成 Mock Feeds
            self.feeds = (1...10).map { feed in
                FeedItem(
                    id: feed,
                    title: "用户动态通知 #\(feed)",
                    desc: "这是一条模拟的动态内容，展示了列表的样式布局。",
                    time: "\(feed)分钟前"
                )
            }
            
            stopLoading()
        }
    }
}
