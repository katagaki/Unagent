//
//  SiteSettingsNewView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import Komponents
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
                        Text("Shared.DomainName")
                    }
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                } footer: {
                    Text(verbatim: NSLocalizedString("SiteSettings.DomainName.Example", comment: ""))
                }
                Section {
                    TextEditor(text: $userAgent)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .font(.monospaced(.custom("", size: 14.0, relativeTo: .body))())
                        .frame(height: 120)
                        .scrollIndicators(.never)
                } header: {
                    HStack(alignment: .center) {
                        ListSectionHeader(text: "Shared.UserAgent")
                            .font(.body)
                        Spacer()
                        if UIPasteboard.general.hasStrings {
                            Button {
                                if let pasteboardString = UIPasteboard.general.string {
                                    userAgent = pasteboardString
                                }
                            } label: {
                                Text("Shared.Paste")
                            }
                            .textCase(.none)
                        }
                    }
                } footer: {
                    Text("SiteSettings.DomainName.Footer")
                }
                PresetsSection {
                    return userAgent
                } onSelect: { selectedUserAgent in
                    userAgent = selectedUserAgent
                }
            }
            .navigationTitle("ViewTitle.SiteSettings.New")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        willCreateSiteSetting = false
                        dismiss()
                    } label: {
                        Text("Shared.Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        willCreateSiteSetting = true
                        dismiss()
                    } label: {
                        Text("Shared.Add")
                    }
                    .disabled(domain == "" || userAgent == "")
                }
            }
        }
    }
}
