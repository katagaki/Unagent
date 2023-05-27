//
//  UserAgentTableViewController.swift
//  Shared (App)
//
//  Created by 堅書 on 2023/05/27.
//

import Foundation
import UIKit

let defaults: UserDefaults = UserDefaults(suiteName: "group.com.tsubuzaki.BingBong")!

class UserAgentTableViewController: UITableViewController, UITextViewDelegate {
    
    // TODO: Use plist for data
    var data: [UserAgent] = [UserAgent(name: "Default (Don't Change)",
                                       imageName: "Safari",
                                       userAgent: "Don'tChange"),
                             UserAgent(name: "Safari 16.5 (macOS)",
                                       imageName: "Safari",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.5 Safari/605.1.15"),
                             UserAgent(name: "Microsoft Edge 113 (iOS)",
                                       imageName: "Edgeium",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 EdgiOS/113.0.1774.50 Mobile/15E148 Safari/604.1"),
                             UserAgent(name: "Microsoft Edge 113 (macOS)",
                                       imageName: "Edgeium",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36 Edg/113.0.1774.57"),
                             UserAgent(name: "Microsoft Edge 113 (Android)",
                                       imageName: "Edgeium",
                                       userAgent: "Mozilla/5.0 (Linux; Android 13.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.5672.162 Mobile Safari/537.36 EdgA/113.0.1774.50"),
                             UserAgent(name: "Microsoft Edge 18 (EdgeHTML)",
                                       imageName: "EdgeHTML",
                                       userAgent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/18.17763"),
                             UserAgent(name: "Google Chrome 113 (iOS)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/113.0.5672.121 Mobile/15E148 Safari/604.1"),
                             UserAgent(name: "Google Chrome 113 (macOS)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36"),
                             UserAgent(name: "Google Chrome 113 (Android)",
                                       imageName: "Chrome",
                                       userAgent: "Mozilla/5.0 (Linux; Android 13.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.5672.162 Mobile Safari/537.36"),
                             UserAgent(name: "Google App 265 (iOS)",
                                       imageName: "Google",
                                       userAgent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) GSA/265.0.533000180 Mobile/15E148 Safari/604.1"),
                             UserAgent(name: "Internet Explorer 6",
                                       imageName: "IE",
                                       userAgent: "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; SV1)"),
                             UserAgent(name: "Internet Explorer 11",
                                       imageName: "IE",
                                       userAgent: "Mozilla/5.0 (Windows NT 10.0; Trident/7.0; rv:11.0) like Gecko"),
                             UserAgent(name: "Empty User Agent",
                                       imageName: "Empty",
                                       userAgent: "")]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if defaults.string(forKey: "UserAgent") == nil {
            defaults.set(data[0].userAgent, forKey: "UserAgent")
        }
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1: return data.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0: return "Current User Agent"
        case 1: return "Presets"
        default: return ""
        }
        
    }
    
    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 0:
            return "After you change your user agent, Safari may refresh automatically when you return to it."
        default: return ""
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "CustomUserAgentInputCell")!
            let textView = cell.contentView.subviews[0] as! UITextView
            textView.textContainer.lineFragmentPadding = 20.0
            textView.text = ""
            if let currentUserAgent = defaults.string(forKey: "UserAgent") {
                if currentUserAgent != "Don'tChange" {
                    textView.text = currentUserAgent
                }
            }
            textView.delegate = self
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "BuiltInUserAgentCell")!
            cell.imageView!.image = UIImage(named: data[indexPath.row].imageName)
            cell.textLabel!.text = data[indexPath.row].name
            if data[indexPath.row].userAgent == defaults.string(forKey: "UserAgent") {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            defaults.set(data[indexPath.row].userAgent, forKey: "UserAgent")
            tableView.reloadData()
        default: break
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        defaults.set(textView.text, forKey: "UserAgent")
        tableView.reloadSections(IndexSet(integer: 1), with: .none)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if(text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}

struct UserAgent: Codable {
    var name: String
    var imageName: String
    var userAgent: String
}
