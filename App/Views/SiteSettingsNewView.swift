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
    
    @State var presets: [Preset] = []
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
                    ListSectionHeader(text: "User Agent")
                        .font(.body)
                } footer: {
                    Text("This user agent will only apply to pages in the domain specified.")
                }
                Section {
                    ForEach(presets, id: \.name) { preset in
                        HStack(spacing: 8.0) {
                            Image(preset.imageName)
                            Text(preset.name)
                            Spacer()
                            if preset.userAgent == userAgent {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16.0))
                                    .symbolRenderingMode(.multicolor)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            userAgent = preset.userAgent
                        }
                    }
                } header: {
                    ListSectionHeader(text: "Presets")
                        .font(.body)
                }
            }
            .navigationTitle("New Site Setting")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let url = Bundle.main.url(forResource: "Presets", withExtension: "json"),
                   let data = try? Data(contentsOf: url) {
                    let decoder = JSONDecoder()
                    if let presets = try? decoder.decode([Preset].self, from: data) {
                        self.presets = presets
                    }
                }
            }
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
                    .disabled(domain == "" || userAgent == "")
                }
            }
        }
    }
}
