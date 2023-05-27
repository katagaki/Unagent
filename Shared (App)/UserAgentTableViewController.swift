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
    var data: [UserAgent] = [UserAgent(name: "Default (Don't Change)",
                                       imageName: "",
                                       userAgent: "Don'tChange"),
                             UserAgent(name: "Microsoft Edge (iOS)",
                                       imageName: "Edge",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 EdgiOS/113.0.1774.50 Mobile/15E148 Safari/605.1.15"),
                             UserAgent(name: "Microsoft Edge (macOS)",
                                       imageName: "Edge",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/113.0.1774.57"),
                             UserAgent(name: "Google Chrome (macOS)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"),
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
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return data.count
        } else {
            return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Built-in User Agents"
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 1 {
            return "You may need to refresh Safari a few times for the changes to take effect."
        } else {
            return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.imageView!.image = UIImage(named: data[indexPath.row].imageName)
            cell.textLabel!.text = data[indexPath.row].name
            if data[indexPath.row].userAgent == selectedUserAgent {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        } else {
            return UITableViewCell()
        }
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
