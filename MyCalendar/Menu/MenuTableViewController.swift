//
//  MenuTableViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit

class MenuTableViewController: UITableViewController {

    @IBOutlet var buttomView: UIView!
    let menuList = ["일정(캘린더)", "설정"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "MENU"
//        self.navigationController?.navigationBar.barTintColor = UIColor().customPinkBar
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        tableView.backgroundColor = UIColor().customGray
        buttomView.backgroundColor = UIColor().customGray
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = menuList[indexPath.row]
        cell.textLabel?.font = fontCoreDreamLight(fontSize: 18)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.dismiss(animated: true, completion: nil)
        } else if indexPath.row == 1 {
            let moveView = self.storyboard?.instantiateViewController(withIdentifier: "SettingViewController")
            
            let navi = UINavigationController(rootViewController: moveView!)
            navi.modalPresentationStyle = .fullScreen
            navi.modalTransitionStyle = .crossDissolve
            
            self.present(navi, animated: true, completion: nil)
        }
    }
}
