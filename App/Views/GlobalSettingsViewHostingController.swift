//
//  GlobalSettingsViewHostingController.swift
//  Unagent
//
//  Created by 堅書 on 2023/05/28.
//

import SwiftUI

class GlobalSettingsViewHostingController: UIHostingController<GlobalSettingsView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: GlobalSettingsView())
    }
}
