//
//  MoreView.swift
//  Unagent
//
//  Created by シンジャスティン on 2023/08/23.
//

import Komponents
import SwiftUI

struct MoreView: View {
    
    @State var viewPath: [ViewPath] = []
    @AppStorage(wrappedValue: false, "HideSetUpTab") var hideSetUpTab: Bool

    var body: some View {
        NavigationStack(path: $viewPath) {
            MoreList(repoName: "katagaki/Unagent", viewPath: ViewPath.moreAttributions) {
                if hideSetUpTab {
                    Section {
                        Button("More.ShowSetUpTab") {
                            withAnimation {
                                hideSetUpTab = false
                            }
                        }
                    } header: {
                        ListSectionHeader(text: "More.General")
                            .font(.body)
                    }
                }
            }
            .navigationDestination(for: ViewPath.self) { viewPath in
                switch viewPath {
                    case .moreAttributions: LicensesView(licenses: [
                        License(libraryName: "Translations", text:
"""
Translations in this app were kindly provided by the below contributors:

- Portugese (Brazil): Gabriel Garcia

Thank you to every contributor who has contributed to the project!
"""),
                        License(libraryName: "FaviconFinder", text:
"""
Copyright (c) 2022 William Lumley <will@lumley.io>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
"""),
                        License(libraryName: "SwiftSoup", text:
"""
MIT License

Copyright (c) 2016 Nabil Chatbi

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
""")])
                }
            }
        }
    }
}
