//
//  CombineRoute.swift
//  SwiftUIDemo
//

import SwiftUI

enum CombineRoute: String, AppPathRoute {
    case guide = "/combineGuide"
    case intro = "/combineIntro"
    case publishers = "/combinePublishers"
    case subjects = "/combineSubjects"
    case operators = "/combineOperators"
    case combining = "/combineCombining"
    case errorHandling = "/combineErrorHandling"
    case scheduling = "/combineScheduling"
    case swiftUI = "/combineSwiftUI"
    case practical = "/combinePractical"
}

extension CombineRoute {

    @ViewBuilder
    static func view(for push: RoutePush<CombineRoute>) -> some View {
        switch push.route {
        case .guide: CombineGuideView()
        case .intro: CombineIntroTutorialView()
        case .publishers: CombinePublishersTutorialView()
        case .subjects: CombineSubjectsTutorialView()
        case .operators: CombineOperatorsTutorialView()
        case .combining: CombineCombiningTutorialView()
        case .errorHandling: CombineErrorTutorialView()
        case .scheduling: CombineSchedulingTutorialView()
        case .swiftUI: CombineSwiftUITutorialView()
        case .practical: CombinePracticalTutorialView()
        }
    }
}
