//
//  UserAgentTableViewController.swift
//  Shared (App)
//
//  Created by 堅書 on 2023/05/27.
//

import Foundation
import UIKit

let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tsubuzaki.BingBong")!

class UserAgentTableViewController: UITableViewController {
    
    // TODO: Use plist for data
    var data: [UserAgent] = [UserAgent(name: "Safari (iOS)",
                                       imageName: "Safari",
                                       userAgent: "Don'tChange"),
                             UserAgent(name: "Safari 16.5 (macOS)",
                                       imageName: "Safari",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15"),
                             UserAgent(name: "Microsoft Edge 113 (iOS)",
                                       imageName: "Edgeium",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 EdgiOS/113.0.1774.50 Mobile/15E148 Safari/605.1.15"),
                             UserAgent(name: "Microsoft Edge 113 (macOS)",
                                       imageName: "Edgeium",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/113.0.1774.57"),
                             UserAgent(name: "Microsoft Edge 18 (EdgeHTML)",
                                       imageName: "EdgeHTML",
                                       userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/18.17763"),
                             UserAgent(name: "Google Chrome 113 (iOS)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/113.0.5672.121 Mobile/15E148 Safari/605.1.15"),
                             UserAgent(name: "Google Chrome 113 (macOS)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"),
                             UserAgent(name: "Google App 164 (iOS)",
                                       imageName: "Google",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) GSA/164.0.378717864 Mobile/15E148 Safari/605.1.15"),
                             UserAgent(name: "Internet Explorer 6",
                                       imageName: "IE",
                                       userAgent: "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"),
                             UserAgent(name: "Internet Explorer 11",
                                       imageName: "IE",
                                       userAgent: "Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko"),
                             UserAgent(name: "Empty User Agent",
                                       imageName: "Empty",
                                       userAgent: "")]
    var selectedUserAgent: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let selectedUserAgent = defaults.string(forKey: "SelectedUserAgentRule") {
            self.selectedUserAgent = selectedUserAgent
            tableView.reloadData()
        } else {
            selectedUserAgent = data[0].userAgent
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Built-in User Agents"
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if let selectedUserAgent = defaults.string(forKey: "SelectedUserAgentRule") {
            if selectedUserAgent != "Don'tChange" {
                return "After you change your user agent, Safari may refresh when you return to it.\n\nCurrent User Agent: \(selectedUserAgent)"
            }
        }
        return "After you change your user agent, Safari may refresh when you return to it."
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.imageView!.image = UIImage(named: data[indexPath.row].imageName)
        cell.textLabel!.text = data[indexPath.row].name
        if data[indexPath.row].userAgent == selectedUserAgent {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedUserAgent = data[indexPath.row].userAgent
        defaults.set(selectedUserAgent, forKey: "SelectedUserAgentRule")
        tableView.reloadData()
    }
    
}

struct UserAgent: Codable {
    var name: String
    var imageName: String
    var userAgent: String
}
