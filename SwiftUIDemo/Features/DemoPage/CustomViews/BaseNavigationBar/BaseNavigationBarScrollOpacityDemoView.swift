//
//  BaseNavigationBarScrollOpacityDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

private enum ScrollOpacityDemoMetrics {
    static let headerImageHeight: CGFloat = 200
    static let coverImageURL =
        "https://pic.rmb.bdstatic.com/bjh/3f6180389584/241014/1e486a31dc93b035dcd725943de1c92f.jpeg"
}

struct BaseNavigationBarScrollOpacityDemoView: View {
    @State private var scrollOffset: CGFloat = 0

    private let listItems = (1...20).map { "列表项 \($0)" }

    private var barBackgroundOpacity: Double {
        min(1, Double(scrollOffset / ScrollOpacityDemoMetrics.headerImageHeight))
    }

    private var barBackgroundColor: Color {
        Color.red.opacity(barBackgroundOpacity)
    }

    private var barForegroundColor: Color {
        barBackgroundOpacity < 0.5 ? .white : AppColors.textPrimary
    }

    var body: some View {
        scrollView
            .baseNavigationBar(
                title: "滚动渐变",
                barOverlaysContent: true,
                backgroundColor: barBackgroundColor,
                showsDivider: false,
                titleColor: barForegroundColor
            )
    }

    private var scrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerImage
                listContent
            }
        }
        .ignoresSafeArea(edges: .top)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y
        } action: { _, offsetY in
            scrollOffset = max(0, offsetY)
        }
    }

    private var headerImage: some View {
        AppNetworkImage(
            url: ScrollOpacityDemoMetrics.coverImageURL,
            contentMode: .fill,
            size: CGSize(
                width: UIScreen.main.bounds.width,
                height: ScrollOpacityDemoMetrics.headerImageHeight
            )
        )
        .frame(height: ScrollOpacityDemoMetrics.headerImageHeight)
        .frame(maxWidth: .infinity)
        .clipped()
    }

    private var listContent: some View {
        VStack(spacing: 0) {
            ForEach(listItems, id: \.self) { item in
                HStack {
                    Text(item)
                        .appFont(AppFonts.body)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary.opacity(0.5))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(AppColors.background)

                Divider()
                    .padding(.leading, 16)
            }
        }
    }
}
