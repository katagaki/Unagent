//
//  MainTabView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import StoreKit
import SwiftUI

struct MainTabView: View {

    @Environment(\.requestReview) var requestReview
    @AppStorage(wrappedValue: false, "ReviewPrompted", store: .standard) var hasReviewBeenPrompted: Bool
    @AppStorage(wrappedValue: 0, "LaunchCount", store: .standard) var launchCount: Int

    var body: some View {
        TabView {
            Tab("Tab.SetUp", systemImage: "checklist") {
                SetUpView()
            }
            Tab("Tab.UserAgents", systemImage: "globe") {
                UserAgentsView()
            }
            Tab("Tab.More", systemImage: "ellipsis") {
                MoreView()
            }
        }
        .task {
            launchCount += 1
            if launchCount > 2 && !hasReviewBeenPrompted {
                requestReview()
                hasReviewBeenPrompted = true
            }
        }
    }
}
