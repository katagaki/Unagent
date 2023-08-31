//
//  MoreView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import SwiftUI

class MoreViewController: UIHostingController<MoreView> {
    required init?(coder: NSCoder) {
        super.init(coder: coder, rootView: MoreView())
    }
}

struct MoreView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Link(destination: URL(string: "https://x.com/katagaki_")!) {
                        HStack {
                            ListRow(image: "ListIcon.Twitter",
                                    title: "Post on X",
                                    subtitle: "@katagaki_",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "mailto:ktgk.public@icloud.com")!) {
                        HStack {
                            ListRow(image: "ListIcon.Email",
                                    title: "Email Me",
                                    subtitle: "ktgk.public@icloud.com",
                                    includeSpacer: true)
                            Image(systemName: "arrow.up.forward.app")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                    Link(destination: URL(string: "https://github.com/katagaki/Unagent")!) {
                        HStack {
                            ListRow(image: "ListIcon.GitHub",
                                    title: "Read Source Code",
                                    subtitle: "katagaki/Unagent",
                                    includeSpacer: true)
                            Image(systemName: "safari")
                                .opacity(0.5)
                        }
                        .foregroundColor(.primary)
                    }
                } header: {
                    ListSectionHeader(text: "Help & Support")
                        .font(.body)
                }
                Section {
                    NavigationLink {
                        LicensesView()
                    } label: {
                        ListRow(image: "ListIcon.Attributions",
                                title: "Attributions")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("More")
        }
    }
}
