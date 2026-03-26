//
//  AttributionsView.swift
//  Unagent
//

import SwiftUI

struct AttributionsView: View {

    var body: some View {
        List {
            ForEach(Dependency.all) { dependency in
                Section {
                    Text(dependency.licenseText)
                        .font(.caption)
                        .monospaced()
                        .listRowBackground(Color.clear)
                } header: {
                    Text(dependency.name)
                }
            }
        }
        .listStyle(.grouped)
        .navigationTitle("More.Attribution")
        .navigationBarTitleDisplayMode(.inline)
        .scrollContentBackground(.hidden)
        .gradientBackground()
    }
}

private struct Dependency: Identifiable {
    let id: String
    let name: String
    let licenseText: String

    static let all: [Dependency] = [
        Dependency(
            id: "translations",
            name: "Translations",
            licenseText: """
            Translations in this app were kindly provided by the below contributors:

            - Portugese (Brazil): Gabriel Garcia

            Thank you to every contributor who has contributed to the project!
            """
        ),
        Dependency(
            id: "faviconfinder",
            name: "FaviconFinder",
            licenseText: """
            Copyright (c) 2022 William Lumley <will@lumley.io>

            Permission is hereby granted, free of charge, to any person obtaining a copy \
            of this software and associated documentation files (the "Software"), to deal \
            in the Software without restriction, including without limitation the rights \
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
            copies of the Software, and to permit persons to whom the Software is \
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in \
            all copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN \
            THE SOFTWARE.
            """
        ),
        Dependency(
            id: "swiftsoup",
            name: "SwiftSoup",
            licenseText: """
            MIT License

            Copyright (c) 2016 Nabil Chatbi

            Permission is hereby granted, free of charge, to any person obtaining a copy \
            of this software and associated documentation files (the "Software"), to deal \
            in the Software without restriction, including without limitation the rights \
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell \
            copies of the Software, and to permit persons to whom the Software is \
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all \
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR \
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, \
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE \
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER \
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, \
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE \
            SOFTWARE.
            """
        ),
        Dependency(
            id: "chrome-versions",
            name: "berstend/chrome-versions",
            licenseText: """
            Unagent uses data from berstend/chrome-versions to update Google Chrome \
            version numbers for macOS and Android presets.

            For more information, visit https://github.com/nicedoc/chrome-versions
            """
        ),
        Dependency(
            id: "itunes-lookup-api",
            name: "Apple iTunes Lookup API",
            licenseText: """
            Unagent uses data from the Apple iTunes Lookup API to update iOS app \
            version numbers for Chrome, Edge, and Google App presets.

            For more information, visit https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/
            """
        ),
        Dependency(
            id: "edge-release-notes",
            name: "Microsoft Edge Release Notes",
            licenseText: """
            Unagent uses data from Microsoft Edge release notes to update Microsoft \
            Edge version numbers for macOS, Android, and iOS presets.

            For more information, visit https://learn.microsoft.com/en-us/deployedge/microsoft-edge-relnote-stable-channel
            """
        ),
    ]
}
