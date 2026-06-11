//
//  MoyaDemoView.swift
//  SwiftUIDemo
//
//  NetworkDemo 模块 · Demo 页面。
//

import SwiftUI

struct MoyaDemoView: View {

  @StateObject private var viewModel = MoyaDemoViewModel()

  var body: some View {
    List {
      Section {
        Text("NetworkDemo 模块：API / Service / View 都在同一目录下")
          .font(.caption)
          .foregroundStyle(AppColors.textSecondary)
      }

      Section("操作") {
        demoButton("加载帖子列表", icon: "list.bullet", action: viewModel.loadPosts)
        demoButton("加载帖子详情 (id=1)", icon: "doc.text", action: viewModel.loadPostDetail)
        demoButton("创建帖子 (POST)", icon: "plus.circle", action: viewModel.createPost)
      }

      Section("状态") {
        if viewModel.isLoading {
          HStack {
            ProgressView()
            Text("请求中…")
          }
        }

        Text(viewModel.lastActionLog)
          .font(.caption)
          .foregroundStyle(AppColors.textSecondary)

        if let error = viewModel.errorMessage {
          Text(error)
            .font(.caption)
            .foregroundStyle(AppColors.error)
        }
      }

      if let post = viewModel.selectedPost {
        Section("最新结果") {
          VStack(alignment: .leading, spacing: 6) {
            Text(post.title).font(.headline)
            Text(post.body).font(.caption).foregroundStyle(AppColors.textSecondary)
            Text("id: \(post.id) · userId: \(post.userId)")
              .font(.caption2)
              .foregroundStyle(AppColors.textSecondary)
          }
        }
      }

      if !viewModel.posts.isEmpty {
        Section("帖子列表 (\(viewModel.posts.count))") {
          ForEach(viewModel.posts.prefix(20)) { post in
            VStack(alignment: .leading, spacing: 4) {
              Text(post.title)
                .font(.subheadline)
                .lineLimit(1)
              Text(post.body)
                .font(.caption)
                .foregroundStyle(AppColors.textSecondary)
                .lineLimit(2)
            }
            .padding(.vertical, 2)
          }
        }
      }
    }
    .baseNavigationBar(title: "Moya 网络 Demo")
  }

  private func demoButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Label(title, systemImage: icon)
        .foregroundStyle(AppColors.textPrimary)
    }
    .buttonStyle(.plain)
    .disabled(viewModel.isLoading)
  }
}
