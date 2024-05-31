//
//  SiteSettingEditor.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/05/28.
//

import Komponents
import SwiftUI

struct SiteSettingEditor: View {
    
    @Environment(\.dismiss) var dismiss

    @State var mode: EditorMode

    @Binding var domain: String
    @Binding var userAgent: String
    @Binding var shouldSave: Bool
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    TextField(text: $domain) {
                        Text("Shared.DomainName")
                    }
                    .autocorrectionDisabled()
                    .autocapitalization(.none)
                    .disabled(mode == .edit)
                    .foregroundStyle(mode == .edit ? Color.secondary : Color.primary)
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
            .navigationTitle(mode == .new ? "ViewTitle.SiteSettings.New" : "ViewTitle.SiteSettings.Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        shouldSave = false
                        dismiss()
                    } label: {
                        Text("Shared.Cancel")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        shouldSave = true
                        dismiss()
                    } label: {
                        switch mode {
                        case .new:
                            Text("Shared.Add")
                        case .edit:
                            Text("Shared.Save")
                        }
                    }
                    .disabled(domain == "" || userAgent == "")
                }
            }
        }
    }
}
