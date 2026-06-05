//
//  HomeView.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI

struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var navigator = Navigator()
    
    var body: some View {
        homeContent
            .navigator(navigator)
    }

    private var homeContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // 1. Banner 区
                VStack(alignment: .leading, spacing: 16) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(viewModel.banners) { banner in
                                BannerCard(item: banner)
                                    .onTapGesture {
                                        // 跳转 WebView
                                        push(.homeBanner, query: ["url": banner.url])
                                    }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
                
                // 2. 金刚区 (功能菜单 Grid)
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
                    FeatureButton(icon: "doc.text.fill", color: .blue, text: "文档")
                    FeatureButton(icon: "star.fill", color: .orange, text: "收藏")
                    FeatureButton(icon: "bell.fill", color: .red, text: "消息")
                    FeatureButton(icon: "gearshape.fill", color: .gray, text: "更多")
                }
                .padding(.horizontal)
                
                // 3. 最新动态列表 (List)
                VStack(alignment: .leading, spacing: 12) {
                    Text("最新动态")
                        .appFont(AppFonts.h2)
                        .padding(.horizontal)
                    
                    ForEach(viewModel.feeds) { item in
                        FeedRow(item: item)
                            .onTapGesture {
                                // 跳转详情
                                push(.homeDetail, query: ["id": String(item.id)])
                            }
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .padding(.bottom, 20)
        }
        .refreshable {
            await viewModel.fetchData()
        }
        .onAppear {
            Task { await viewModel.fetchData() }
        }
        .overlay {
            if viewModel.state == .loading {
                LoadingView()
            }
        }
    }

    private func push(
        _ route: TemplateRoute,
        query: [String: String] = [:],
        extra: (any Hashable)? = nil
    ) {
        navigator.push(route, query: query, extra: extra)
    }
}

// MARK: - 局部小组件 (为了代码整洁)

struct BannerCard: View {
    let item: BannerItem
    
    var color: Color {
        switch item.color {
        case "blue": return .blue
        case "orange": return .orange
        default: return .pink
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color.gradient)
                .frame(width: 280, height: 140)
            
            Text(item.title)
                .font(.headline)
                .foregroundStyle(.white)
                .padding()
        }
    }
}

struct FeatureButton: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(color)
                .clipShape(Circle())
            
            Text(text)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

struct FeedRow: View {
    let item: FeedItem
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundStyle(AppColors.primary)
                .padding(8)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.title)
                        .appFont(AppFonts.body)
                        .fontWeight(.medium)
                    Spacer()
                    Text(item.time)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                }
                
                Text(item.desc)
                    .appFont(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // 扩大点击区域
    }
}
