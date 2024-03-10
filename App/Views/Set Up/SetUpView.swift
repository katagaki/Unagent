//
//  SetUpView.swift
//  Unagent
//
//  Created by シン・ジャスティン on 2024/03/08.
//

import Komponents
import SwiftUI

struct SetUpView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("SetUp.Step1")
                    .lineSpacing(4.0)
                    #if targetEnvironment(macCatalyst)
                    Link(destination: URL(string: "https://www.example.com")!, label: {
                        Text("SetUp.OpenSafari")
                    })
                    #else
                    Link(destination: URL(string: UIApplication.openSettingsURLString)!, label: {
                        Text("SetUp.OpenSettings")
                    })
                    #endif
                } header: {
                    ListSectionHeader(text: "SetUp.Step1.Title")
                        .font(.body)
                }
                Section {
                    Text("SetUp.Step2")
                    .lineSpacing(4.0)
                    Link(destination: URL(string: "https://www.example.com")!, label: {
                        Text("SetUp.OpenSafari")
                    })
                } header: {
                    ListSectionHeader(text: "SetUp.Step2.Title")
                        .font(.body)
                }
            }
            .navigationTitle("ViewTitle.SetUp")
        }
    }
}
