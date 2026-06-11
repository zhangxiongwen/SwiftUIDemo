//
//  CombineTutorialComponents.swift
//  SwiftUIDemo
//
//  Combine 教程通用 UI 组件：说明卡片、日志面板、代码展示、演示按钮等。
//

import SwiftUI

// MARK: - 教程目录行

struct CombineCatalogRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let level: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .foregroundStyle(AppColors.textPrimary)
                        Text(level)
                            .font(.caption2.weight(.medium))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppColors.primary.opacity(0.12))
                            .foregroundStyle(AppColors.primary)
                            .clipShape(Capsule())
                    }
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary.opacity(0.6))
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 概念说明卡片

struct TutorialConceptCard: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "lightbulb.fill")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)

            Text(content)
                .font(.subheadline)
                .foregroundStyle(AppColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 代码片段展示

struct TutorialCodeBlock: View {
    let title: String
    let code: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.textSecondary)

            ScrollView(.horizontal, showsIndicators: false) {
                Text(code)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - 实时日志面板（展示 Combine 输出）

struct TutorialLogPanel: View {
    let title: String
    let logs: [String]
    var emptyHint: String = "点击「运行演示」查看 Combine 输出"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.textSecondary)
                Spacer()
                Text("\(logs.count) 条")
                    .font(.caption2)
                    .foregroundStyle(AppColors.textSecondary)
            }

            if logs.isEmpty {
                Text(emptyHint)
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .frame(maxWidth: .infinity, minHeight: 80, alignment: .center)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(logs.enumerated()), id: \.offset) { index, line in
                            HStack(alignment: .top, spacing: 8) {
                                Text("\(index + 1).")
                                    .font(.caption2.monospacedDigit())
                                    .foregroundStyle(AppColors.textSecondary)
                                    .frame(width: 22, alignment: .trailing)
                                Text(line)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(AppColors.textPrimary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
                .frame(maxHeight: 180)
            }
        }
        .padding(12)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - 演示操作区

struct TutorialDemoActions: View {
    let runTitle: String
    let onRun: () -> Void
    var onReset: (() -> Void)? = nil
    var isRunning: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Button {
                onRun()
            } label: {
                Label(runTitle, systemImage: "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRunning)

            if let onReset {
                Button("清空日志") {
                    onReset()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

// MARK: - 日志收集（教程 ViewModel 共用）

/// ViewModel 遵循此协议后，日志变化会自动驱动 SwiftUI 刷新。
@MainActor
protocol TutorialLogging: AnyObject, ObservableObject {
    var logLines: [String] { get set }
}

extension TutorialLogging {
    func appendLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .standard)
        logLines.append("[\(timestamp)] \(message)")
    }

    func resetLogs() {
        logLines.removeAll()
    }
}

// MARK: - 教程页面容器

struct CombineTutorialPage<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .baseNavigationBar(title: title)
    }
}
