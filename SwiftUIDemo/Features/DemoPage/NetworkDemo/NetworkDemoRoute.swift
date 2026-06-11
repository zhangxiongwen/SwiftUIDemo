//
//  NetworkDemoRoute.swift
//  SwiftUIDemo
//

import SwiftUI

enum NetworkDemoRoute: String, AppPathRoute {
  case moyaDemo = "/networkDemo/moya"
}

extension NetworkDemoRoute {

  @ViewBuilder
  static func view(for push: RoutePush<NetworkDemoRoute>) -> some View {
    switch push.route {
    case .moyaDemo: MoyaDemoView()
    }
  }
}
