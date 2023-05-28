//
//  SiteSettingsNewView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import SwiftUI

struct SiteSettingsNewView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @Binding var domain: String
    @Binding var userAgent: String
    @Binding var willCreateSiteSetting: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(text: $domain) {
                        Text("Domain Name")
                    }
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                } footer: {
                    Text(verbatim: "e.g. www.example.com")
                }
                Section {
                    TextEditor(text: $userAgent)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .font(.monospaced(.body)())
                        .frame(height: 150)
                        .scrollIndicators(.never)
                } header: {
                    Text("User Agent")
                } footer: {
                    Text("This user agent will only apply to pages in the domain specified.")
                }
            }
            .navigationTitle("New Site Setting")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        willCreateSiteSetting = false
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        willCreateSiteSetting = true
                        dismiss()
                    } label: {
                        Text("Add")
                    }
                }
            }
        }
    }
}
