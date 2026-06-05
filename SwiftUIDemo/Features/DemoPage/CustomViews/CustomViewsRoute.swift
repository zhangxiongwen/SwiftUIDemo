//
//  CustomViewsRoute.swift
//  SwiftUIDemo
//

import SwiftUI

enum CustomViewsRoute: String, AppPathRoute {
    case navBarCatalog = "/navBarCatalog"
    case navBarBasic = "/navBarBasic"
    case navBarHidden = "/navBarHidden"
    case navBarOpacity = "/navBarOpacity"
    case navBarCustom = "/navBarCustom"
    case navBarScrollOpacity = "/navBarScrollOpacity"
    case navBarBackGesture = "/navBarBackGesture"
    case pagePresentDemo = "/pagePresentDemo"
    case dialogDemo = "/dialogDemo"
    case dialogNestDemo = "/dialogNestDemo"
    case presentThenPushDemo = "/presentThenPushDemo"
    case presentThenPushTarget = "/presentThenPushTarget"
    case toastDemo = "/toastDemo"
    case loadingDemo = "/loadingDemo"
    case routeDemo = "/routeDemo"
    case routeParamsDemo = "/routeParamsDemo"
    case routePopStepsDemo = "/routePopStepsDemo"
    case presentNavDeepDismissLayer = "/presentNavDeepDismissLayer"
}

extension CustomViewsRoute {

    @ViewBuilder
    static func view(for push: RoutePush<CustomViewsRoute>) -> some View {
        switch push.route {
        case .navBarCatalog: BaseNavigationBarDemoCatalogView()
        case .navBarBasic: BaseNavigationBarBasicDemoView()
        case .navBarHidden: BaseNavigationBarHiddenDemoView()
        case .navBarOpacity: BaseNavigationBarOpacityDemoView()
        case .navBarCustom: BaseNavigationBarCustomDemoView()
        case .navBarScrollOpacity: BaseNavigationBarScrollOpacityDemoView()
        case .navBarBackGesture: BaseNavigationBarBackGestureDemoView()
        case .pagePresentDemo: PagePresentDemoView()
        case .dialogDemo: DialogDemoView()
        case .dialogNestDemo: DialogNestDemoView()
        case .presentThenPushDemo: PresentThenPushDemoView()
        case .presentThenPushTarget:
            let from = push.query["from"] ?? "?"
            PresentThenPushTargetView(from: from)
        case .toastDemo: ToastDemoView()
        case .loadingDemo: LoadingDemoView()
        case .routeDemo: RouteDemoView()
        case .routeParamsDemo:
            let title = push.query["title"] ?? "—"
            let count = Int(push.query["count"] ?? "") ?? 0
            let extraSource = (push.extra?.base as? RouteParamsDemoExtra)?.source
            let extraDict = push.extra?.base as? [String: String]
            let extraArray = push.extra?.base as? [String]
            RouteParamsDemoView(
                title: title,
                count: count,
                extraSource: extraSource,
                extraDict: extraDict,
                extraArray: extraArray
            )
        case .routePopStepsDemo:
            let layer = Int(push.query["layer"] ?? "") ?? 1
            RoutePopStepsDemoView(layer: layer)
        case .presentNavDeepDismissLayer:
            let depth = Int(push.query["depth"] ?? "") ?? 1
            PresentNavDeepDismissLayerView(depth: depth)
        }
    }
}
