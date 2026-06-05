//
//  RouteParamsDemoView.swift
//  SwiftUIDemo
//

import SwiftUI

struct RouteParamsDemoView: View {
    let title: String
    let count: Int
    var extraSource: String?
    var extraDict: [String: String]?
    var extraArray: [String]?

    var body: some View {
        List {
            Section("query 参数") {
                LabeledContent("title", value: title)
                LabeledContent("count", value: "\(count)")
            }

            if let extraSource {
                Section("extra · 自定义对象") {
                    LabeledContent("source", value: extraSource)
                }
            }

            if let extraDict, !extraDict.isEmpty {
                Section("extra · 字典 [String: String]") {
                    ForEach(extraDict.keys.sorted(), id: \.self) { key in
                        LabeledContent(key, value: extraDict[key] ?? "")
                    }
                }
            }

            if let extraArray, !extraArray.isEmpty {
                Section("extra · 数组 [String]") {
                    ForEach(Array(extraArray.enumerated()), id: \.offset) { index, item in
                        LabeledContent("[\(index)]", value: item)
                    }
                }
            }

            Section("路径") {
                LabeledContent("rawValue", value: CustomViewsRoute.routeParamsDemo.rawValue)
                LabeledContent(
                    "pushPath 示例",
                    value: "\(CustomViewsRoute.routeParamsDemo.rawValue)?title=\(title)&count=\(count)"
                )
            }
        }
        .baseNavigationBar(title: "路由参数页")
    }
}
