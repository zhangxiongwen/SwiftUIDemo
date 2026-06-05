//
//  AppNetworkImage.swift
//  SwiftUIDemo
//
//  Created by rongguanhui on 2025/12/13.
//

import SwiftUI
import Kingfisher

/// 基于 Kingfisher 的网络图片，带占位、淡入与失败重试。
struct AppNetworkImage: View {
    /// 图片 URL 字符串，无效或空则显示占位图。
    let url: String?
    /// Assets 中占位图名称。
    let placeholder: String
    /// 缩放模式。
    let contentMode: SwiftUI.ContentMode
    /// 解码参考尺寸，用于内存优化；`nil` 表示不限制。
    let size: CGSize?

    /// - Parameters:
    ///   - url: 图片地址。
    ///   - placeholder: 占位图资源名，默认 `placeholder_image`。
    ///   - contentMode: 默认 `.fill`。
    ///   - size: 可选解码尺寸上限。
    init(
        url: String?,
        placeholder: String = "placeholder_image", // 请在 Assets 放一张默认图
        contentMode: SwiftUI.ContentMode = .fill,
        size: CGSize? = nil
    ) {
        self.url = url
        self.placeholder = placeholder
        self.contentMode = contentMode
        self.size = size
    }
    
    var body: some View {
        KFImage(URL(string: url ?? ""))
            .placeholder {
                // 加载中或失败时的占位
                Image(placeholder)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
                    .overlay {
                        // 如果需要在占位图上显示 loading 转圈
                        ProgressView()
                            .tint(.gray)
                    }
            }
            // 开启淡入动画
            .fade(duration: 0.25)
            // 内存优化：如果有指定尺寸，按照尺寸缩放，防止大图爆内存
            .resizing(referenceSize: size ?? .zero, mode: .aspectFill)
            // 失败重试
            .retry(maxCount: 3, interval: .seconds(2))
            // 渲染配置
            .resizable()
            .aspectRatio(contentMode: contentMode)
    }
}
