//
//  DoListTableViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2020/04/01.
//  Copyright © 2020 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift
import JJFloatingActionButton

class DoListTableViewController: UITableViewController {

    // Realm에 접근하겠다는 트리거 생성, Realm에 변화가 있다면 무조건 거쳐감!
    let realm = try! Realm()

    // Realm에서 데이터를 가져와 담을 공간 생성
    var realmListDisComplete : Results<MyDailyTable>!    // 미완료 일정 저장 테이블
    var realmListComplete    : Results<MyDailyTable>!    // 완료 일정 저장 테이블
    var realmCategoryList    : Results<MyCategoryTable>! // 카테고리 저장 테이블
    var realmSetting         : MySettingTable!
    
    // 완료 일정 보는 flag
    var flagComplete = false    // true: 일정 완료&미완료 보기, false: 일정 미완료 보기
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        doListViewSetting()
        doListDBSetting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tableView.reloadData()
    }
    
    // MARK: - DB 세팅
    func doListDBSetting() {
        realmListDisComplete = realm.objects(MyDailyTable.self).filter("dailyIsHoliday == 0").filter("dailyComplete == false").sorted(byKeyPath: "dailyDate", ascending: true)
        realmListComplete = realm.objects(MyDailyTable.self).filter("dailyIsHoliday == 0").filter("dailyComplete == true").sorted(byKeyPath: "dailyDate", ascending: true)
        realmCategoryList = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
        
        realmSetting = realm.objects(MySettingTable.self).first
    }
    
    // MARK: - VIEW 세팅
    // MARK: doListViewSetting
    func doListViewSetting() {
        self.title = "일정 목록"
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        
        // navi 버튼 세팅
        let returnButton = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(clickedReturn))
        returnButton.tintColor = .black
        
        self.navigationItem.leftBarButtonItem = returnButton
        
        let completeButton = UIBarButtonItem(image: UIImage(named: "done"), style: .plain, target: self, action: #selector(clickedComplete))
        completeButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItem = completeButton
        
        // 플로팅 버튼 구성
        let actionButton = JJFloatingActionButton()
                        
        actionButton.buttonImage = UIImage(named: "top")
        actionButton.buttonColor = .white
        actionButton.buttonImageColor = .black
        
        actionButton.addItem(title: "topMove", image: UIImage(named: "top")?.withRenderingMode(.alwaysTemplate)) { item in
            self.tableView.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
        }
        view.addSubview(actionButton)
        
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        actionButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        actionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true

    }
    
    // MARK: Button Set
    @objc func clickedReturn() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func clickedComplete() {
        if flagComplete {
            self.navigationItem.rightBarButtonItem?.tintColor = .black
        } else {
            self.navigationItem.rightBarButtonItem?.tintColor = .gray
        }
        flagComplete = !flagComplete
        self.tableView.reloadData()
    }
    
    // MARK: swipeBack
    @IBAction func swipeBack(_ sender: UISwipeGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - 테이블 뷰 구성
    // MARK: numberOfSections
    override func numberOfSections(in tableView: UITableView) -> Int {
        if flagComplete {
            return 2
        } else {
            return 1
        }
    }
    
    // MARK:
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "일정"
        } else {
            return "완료된 일정"
        }
    }
    
    // MARK: heightForRowAt
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    // MARK: numberOfRowsInSection
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if flagComplete {
            if section == 0 {
                return realmListDisComplete.count
            } else {
                return realmListComplete.count
            }
        } else {
            return realmListDisComplete.count
        }
    }
    
    // MARK: cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableViewCell", for: indexPath) as! MainTableViewCell
        
        cell.layer.borderWidth = 0.5
        cell.layer.borderColor = UIColor().customGray.cgColor
        cell.backgroundColor = .white
        
        // cell view setting start
        cell.titleLabel.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 18)
        cell.dateLabel.textAlignment = .center
        
        let dateFormatter: DateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd"
        
        let timeFormatter: DateFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        cell.dateLabel.font = fontCoreDreamLight(fontSize: 18)
        
        cell.timeLabel.textColor = .darkGray
        cell.timeLabel.font = fontCoreDreamLight(fontSize: 13)
        cell.timeLabel.textAlignment = .center
        
        cell.dateButton.setImage(UIImage(named: "right_allow"), for: .normal)
        cell.dateButton.tintColor = UIColor().customGray
        // cell view setting finish
        
        cell.dateNum.textColor = .clear
        cell.dateNum.backgroundColor = .clear
        
        if indexPath.section == 0 {
            let dailyTable = realmListDisComplete[indexPath.row]
            cell.titleLabel.text = dailyTable.dailyTitle
            
            // Obtain the date according to the format.
            let selectedDate: String = dateFormatter.string(from: dailyTable.dailyDate)
            cell.dateLabel.text = "\(selectedDate)"
            
            let selectTime: String = timeFormatter.string(from: dailyTable.dailyDate)
            cell.timeLabel.text = "\(selectTime)"
//                cell.categoryColor.backgroundColor = rgbPalette[dailyTable.dailyCategory]
            
            cell.dateNum.text = "\(dailyTable.dailyNum)"
            
            cell.selectionStyle = .default
            cell.categoryColor.backgroundColor = rgbPalette[realmCategoryList[dailyTable.dailyCategory].categoryColor]

            return cell
        } else {
            cell.backgroundColor = UIColor().customGray
            cell.layer.borderColor = UIColor.white.cgColor
            cell.dateButton.tintColor = .white
            
            let dailyTable = realmListComplete[indexPath.row]
            cell.titleLabel.text = dailyTable.dailyTitle
            
            // Obtain the date according to the format.
            let selectedDate: String = dateFormatter.string(from: dailyTable.dailyDate)
            let selectedTime: String = timeFormatter.string(from: dailyTable.dailyDate)
                    
            cell.dateLabel.text = "\(selectedDate)"
            cell.timeLabel.text = "\(selectedTime)"
            
            cell.dateNum.text = "\(dailyTable.dailyNum)"

            cell.selectionStyle = .default
            cell.categoryColor.backgroundColor = rgbPalette[realmCategoryList[dailyTable.dailyCategory].categoryColor]
            
            return cell
        }
    }
    
    // MARK: didSelectRowAt
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
        
        if cell.selectionStyle != .none {
            let uv = self.storyboard!.instantiateViewController(withIdentifier: "RegisterTableViewController") as! RegisterTableViewController
            
            uv.modalPresentationStyle = .fullScreen
            uv.registerType = .dailyUpdate
            uv.dailyNumber  = Int(cell.dateNum.text!)!
            
            self.navigationController?.pushViewController(uv, animated: true)
        }
    }
    
    // MARK: trailingSwipeActionsConfigurationForRowAt 삭제 처리
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
        
        // 공휴일인 경우 삭제 안되게
        if cell.selectionStyle == .none {
            return nil
        }

        let deleteButton = UIContextualAction(style: .destructive, title: "삭제") { (action : UIContextualAction, view : UIView, success : (Bool) -> Void) in
            
            let deleteNum = Int(cell.dateNum.text!)
            
            // 1. realm data delete
            let deleteObject = self.realm.objects(MyDailyTable.self).filter("dailyNum == \(deleteNum!)")
            //Realm Delete
            try! self.realm.write {
                self.realm.delete(deleteObject)
            }

            self.doListDBSetting()
            self.tableView.reloadData()
        }
        return UISwipeActionsConfiguration(actions: [deleteButton])
        
    }
    
    // MARK: leadingSwipeActionsConfigurationForRowAt 완료/미완료 처리
    override func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
        if indexPath.section == 0 {
            let completeButton = UIContextualAction(style: .normal, title: "완료") { (action : UIContextualAction, view : UIView, success : (Bool) -> Void) in
                
                let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
                let dailyNum = Int(cell.dateNum.text!)!
                
                let editObject = self.realm.objects(MyDailyTable.self).filter("dailyNum == \(dailyNum)").first
                
                try! self.realm.write {
                    editObject?.dailyComplete = true
                }
                
                self.doListDBSetting()
                self.tableView.reloadData()
            }
            completeButton.backgroundColor = .blue
            return UISwipeActionsConfiguration(actions: [completeButton])
        } else {
            let completeButton = UIContextualAction(style: .normal, title: "미완료") { (action : UIContextualAction, view : UIView, success : (Bool) -> Void) in
                
                let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
                let dailyNum = Int(cell.dateNum.text!)!
                
                let editObject = self.realm.objects(MyDailyTable.self).filter("dailyNum == \(dailyNum)").first
                
                try! self.realm.write {
                    editObject?.dailyComplete = false
                }
                
                self.doListDBSetting()
                self.tableView.reloadData()
            }
            completeButton.backgroundColor = .darkGray
            return UISwipeActionsConfiguration(actions: [completeButton])
        }
        
    }
    
}
