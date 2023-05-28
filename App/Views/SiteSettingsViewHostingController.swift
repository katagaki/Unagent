//
//  SiteSettingsViewHostingController.swift
//  Unagent
//
//  Created by 堅書 on 2023/05/28.
//

import SwiftUI

class SiteSettingsViewHostingController: UIHostingController<SiteSettingsView> {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder, rootView: SiteSettingsView())
    }
}
