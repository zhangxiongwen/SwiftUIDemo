//
//  CombineGuideView.swift
//  SwiftUIDemo
//
//  在 App 内阅读 Combine 使用文档（Bundle 中的 CombineGuide.md）。
//

import SwiftUI

struct CombineGuideView: View {
    @State private var content = ""
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.largeTitle)
                        .foregroundStyle(AppColors.textSecondary)
                    Text("文档加载失败")
                        .appFont(AppFonts.h2)
                    Text("请确认 CombineGuide.md 已加入 App 资源。")
                        .appFont(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
            } else if content.isEmpty {
                ProgressView("加载文档…")
            } else {
                ScrollView {
                    if let attributed = try? AttributedString(
                        markdown: content,
                        options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .full)
                    ) {
                        Text(attributed)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    } else {
                        Text(content)
                            .appFont(AppFonts.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .baseNavigationBar(title: "使用文档")
        .onAppear(perform: loadDocument)
    }

    private func loadDocument() {
        guard let url = Bundle.main.url(forResource: "CombineGuide", withExtension: "md"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            loadFailed = true
            return
        }
        content = text
    }
}
