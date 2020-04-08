//
//  WriteViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit

class WriteViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var writeTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        writeTable.dataSource = self
        writeTable.delegate = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        return cell
    }
}
