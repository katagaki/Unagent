//
//  MainTabView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            SetUpView()
                .tabItem {
                    Label("Tab.SetUp", systemImage: "checklist")
                }
            GlobalSettingsView()
                .tabItem {
                    Label("Tab.GlobalSettings", systemImage: "gear")
                }
            SiteSettingsView()
                .tabItem {
                    Label("Tab.SiteSettings", systemImage: "globe")
                }
            MoreView()
                .tabItem {
                    Label("Tab.More", systemImage: "ellipsis")
                }
        }
    }
}
