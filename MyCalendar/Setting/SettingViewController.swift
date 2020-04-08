//
//  SettingViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift

let menuList : [String] = ["일정 노출 갯수 제한 설정", "카테고리 설정(추가/변경/삭제)", "캘린더 색상 설정", "특정 연도 공휴일 불러오기", "모든 일정 초기화", "[오늘Do] 리뷰 쓰기"]

class SettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, XMLParserDelegate {

    // Realm에 접근하겠다는 트리거 생성, Realm에 변화가 있다면 무조건 거쳐감!
    let realm = try! Realm()

    // Realm에서 데이터를 가져와 담을 공간 생성
    var realmList           : Results<MyDailyTable>!    // 일정 저장 테이블
    var realmCategoryList   : Results<MyCategoryTable>! // 카테고리 저장 테이블
    var realmSetting        : MySettingTable?  // 세팅 저장 테이블
    
    @IBOutlet var settingMenuTable: UITableView!
    
    // MARK: - viewDidLoad()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingMenuTable.delegate = self
        settingMenuTable.dataSource = self
        
        realmSetting = self.realm.objects(MySettingTable.self).first

        // Navigation Bar Setting
        self.title = "설정 메뉴"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(clickedLeftMenuButton))
        self.navigationItem.leftBarButtonItem?.tintColor = .black
//        self.navigationController?.navigationBar.barTintColor = UIColor().customPinkBar
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
    }
    
    @objc func clickedLeftMenuButton() {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        self.dismiss(animated: true, completion: nil)
//        let movePage = self.storyboard?.instantiateViewController(withIdentifier: "MainViewController")
//        movePage?.modalPresentationStyle = .fullScreen
//        movePage?.modalTransitionStyle = .crossDissolve
//        self.present(movePage!, animated: true)
    }
    
    // MARK: - TableView numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuList.count
    }
    
    // MARK: - TableView cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingTableViewCell", for: indexPath) as! SettingTableViewCell
        cell.menuTitleLabel.text = menuList[indexPath.row]
        cell.menuTitleLabel.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 18)
        cell.menuTitleButton.setImage(UIImage(named: "right_allow"), for: .normal)
        cell.menuTitleButton.tintColor = UIColor().customPink//.lightGray
        
        cell.layer.borderColor = UIColor().customGray.cgColor//UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5
        return cell
    }
    
    // MARK: - didSelectRowAt
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {             // 일정 갯수 제한 설정
            let alert = UIAlertController(title: "일정 갯수 제한 설정", message: "일정 제한 갯수를 입력해주세요.\nex) 5, 15, 30", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
                if alert.textFields?[0].text?.count == 0 {
                    return
                }
                
                let inputIndex : Int = Int(alert.textFields?[0].text ?? "10")!
                
                try! self.realm.write {
                    self.realmSetting!.dailyLimitCount = inputIndex
                }
                
                let confirmAlert = UIAlertController(title: "설정 완료", message: "", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(confirmAlert, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            
            alert.addTextField { (inputText) in
                inputText.keyboardType = .numberPad
                inputText.placeholder = "ex)20"
                inputText.text = "\(self.realmSetting!.dailyLimitCount)"
            }
            
            self.present(alert, animated: true)
        } else if indexPath.row == 1 {      // 카테고리 설정
            
            let movePage = self.storyboard?.instantiateViewController(withIdentifier: "CategorySettingViewController") as! CategorySettingViewController
            
            let navi = UINavigationController(rootViewController: movePage)
            navi.modalPresentationStyle = .fullScreen
            navi.modalTransitionStyle = .flipHorizontal
            
            self.present(navi, animated: true)
            
        } else if indexPath.row == 4 {      // 일정 초기화
            
            let alert = UIAlertController(title: "일정 초기화", message: "모든 일정을 삭제하고, 초기화 하시겠습니까?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
                try! self.realm.write {
                    self.realmList = self.realm.objects(MyDailyTable.self).sorted(byKeyPath: "dailyDate", ascending: true)
                    self.realm.delete(self.realmList)
                    
                    let updateObject = self.realm.objects(MySettingTable.self).first
                    updateObject?.holidayList.removeAll()
                    
                    let confirmAlert = UIAlertController(title: "모든 일정이 삭제되었습니다.", message: "", preferredStyle: .alert)
                    confirmAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                    self.present(confirmAlert, animated: true)
                }
            }))
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            self.present(alert, animated: true)
            
        } else if indexPath.row == 2 {  // 캘린더 색상 설정
            
            let movePage = self.storyboard?.instantiateViewController(withIdentifier: "CalendarColorViewController") as! CalendarColorViewController
            
            let navi = UINavigationController(rootViewController: movePage)
            navi.modalPresentationStyle = .fullScreen
            navi.modalTransitionStyle = .flipHorizontal
            
            self.present(navi, animated: true)
            
        } else if indexPath.row == 3 {  // 입력 연도 공휴일 불러오기
            
            let alert = UIAlertController(title: "특정 연도 입력", message: "공휴일을 가져올 연도를 입력하세요.\n ex) 2020", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
                if alert.textFields?[0].text?.count == 0 {
                    return
                }
                
                let inputIndex : Int = Int(alert.textFields?[0].text ?? "0")!
                
                let confirmAlert = UIAlertController(title: "경고", message: "특정 연도의 공휴일을 가져오게 되면\n기존 등록되어 있는 공휴일과\n중복으로 추가 될 수 있습니다.\n계속 진행하시겠습니까?", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
                    self.requestHoliday(requestYear: inputIndex)
                }))
                confirmAlert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
                self.present(confirmAlert, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: nil))
            
            alert.addTextField { (inputText) in
                inputText.keyboardType = .numberPad
                inputText.placeholder = "ex) 2020"
            }
            
            self.present(alert, animated: true)
            
        } else if indexPath.row == 5 {
            if let url = URL(string: SaveURL.todayDoAppstoreReviewURL),
                UIApplication.shared.canOpenURL(url) {
                if #available(iOS 10.0, *) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                } else {
                    UIApplication.shared.openURL(url)
                }
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    // MARK: - 공휴일 가져오는 함수
    let plist = UserDefaults.standard
    
    var holidayCount : Int = 0
    var holidaySaveBool : Bool = false
    
    func requestHoliday(requestYear: Int) {
//        print("request year is \(requestYear)")
        holidaySave.removeAll() // 데이터 초기화
        holidayCount = 0
        
        // 공휴일 처리, 완료된 일정 다시 복귀할 수 있도록
        
        let requestURL = SaveURL.holidayURL + "solYear=\(requestYear)&numOfRows=30"
        
        guard let xmlParser = XMLParser(contentsOf: URL(string: requestURL)!) else { return }
        
        xmlParser.delegate = self;
        xmlParser.parse()
        
        for item in holidaySave {
//            print("\(item.holidayDate!) : \(item.holidayName!)")
            
            let writeDaily : MyDailyTable = MyDailyTable()
            writeDaily.dailyNum = createNewID()
            writeDaily.dailyTitle = item.holidayName!
            
            let holidayFormatter = DateFormatter()
            holidayFormatter.dateFormat = "yyyyMMdd"
            holidayFormatter.locale = Locale(identifier:"ko_KR")
            
            writeDaily.dailyDate = holidayFormatter.date(from: item.holidayDate!)!
            
            if item.holidayIs == "Y" {
                writeDaily.dailyIsHoliday = 1   // 쉬는 날
            } else {
                writeDaily.dailyIsHoliday = 2   // 안 쉬는 날
            }
            
            // 빈공간 채워놓는 용
            writeDaily.dailyAlertOn = false
            writeDaily.dailyCategory = 0
            writeDaily.dailyComplete = false
            
            // Realm Table에 최종적으로 추가
            try! realm.write {
                realm.add(writeDaily)
            }
        }
        
        if holidaySaveBool {
            let updateObject = self.realm.objects(MySettingTable.self).first
            
            if !((updateObject?.holidayList.contains(requestYear))!) {
                try! self.realm.write {
                    updateObject?.holidayList.append(requestYear)
                }
            }
            
            let addAlert = UIAlertController(title: "알림", message: "입력하신 연도의 공휴일이 등록되었습니다.", preferredStyle: .alert)
            
            addAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            
            self.present(addAlert, animated: true)
        } else {
            let addAlert = UIAlertController(title: "알림", message: "입력하신 연도는 아직 공공 데이터에 입력 되지 않았거나,\n해당 공휴일 데이터가 존재하지 않습니다.", preferredStyle: .alert)
            
            addAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            
            self.present(addAlert, animated: true)
        }
    }
    
    // MARK: 공휴일 Primary Key Function
    func createNewID() -> Int {
        // 기존 realm에 저장되어 있는 id(PK)를 숫자 높은 순으로 정렬, 그 값에 +1
        let realm = try! Realm()
        if let retNext = realm.objects(MyDailyTable.self).sorted(byKeyPath: "dailyNum", ascending : false).first?.dailyNum {
            return retNext + 1
        } else { return 2 }
    }
    
    // XMLParserDelegate 함수
    // XML 파서가 시작 테그를 만나면 호출됨
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        
        /*
         dateName => 휴일 이름
         isHoliday => 쉬는 날 인지
         locdate => 휴일 날짜
         */
        
        if elementName == "dateName" {
            holidaySave.append(MyHoliday())
            plist.set("dateName", forKey: "getData")
//            print("elementName: " + elementName)
        } else if elementName == "isHoliday" {
            plist.set("isHoliday", forKey: "getData")
//            print("elementName: " + elementName)
        } else if elementName == "locdate" {
            plist.set("locdate", forKey: "getData")
//            print("elementName: " + elementName)
        } else if elementName == "totalCount" {
            plist.set("totalCount", forKey: "getData")
//            print("elementName: " + elementName)
        } else {
            plist.set("", forKey: "getData")
        }
    }
     
    // XML 파서가 종료 테그를 만나면 호출됨
    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
//        print("bb: " + elementName)
    }
    
    // 현재 테그에 담겨있는 문자열 전달
    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        let getData = plist.string(forKey: "getData")
        
        if getData == "dateName" {
            if string == "월1일" || string == "1월1일" {
//                print("value : 신정")
                holidaySave[holidayCount].holidayName = "신정"
            } else {
//                print("value : \(string)")
                holidaySave[holidayCount].holidayName = string
            }
        } else if getData == "isHoliday" {
//            print("value : \(string)")
            holidaySave[holidayCount].holidayIs = string
        } else if getData == "locdate" {
//            print("value : \(string)")
            holidaySave[holidayCount].holidayDate = string
            holidayCount = holidayCount + 1
        } else if getData == "totalCount" {
//            print("value : \(string)")
            if Int(string)! == 0 {
                holidaySaveBool = false // 가져온 데이터가 없을 경우 저장 안함
            } else {
                holidaySaveBool = true
            }
        }
    }
}
