//
//  MainViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import FSCalendar
import RealmSwift
import GoogleMobileAds
import SwiftyJSON
import Alamofire

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, XMLParserDelegate {
    
    @IBOutlet var myCalendar: FSCalendar!
    fileprivate let gregorian: NSCalendar! = NSCalendar(calendarIdentifier:NSCalendar.Identifier.gregorian)
    
    @IBOutlet var myDayTable: UITableView!
    @IBOutlet var allDayViewButton: UIButton!
    @IBOutlet var completeViewButton: UIButton!
    
    
    // 광고 UIView
    @IBOutlet var bannerView: GADBannerView!
    
    // Realm에 접근하겠다는 트리거 생성, Realm에 변화가 있다면 무조건 거쳐감!
    let realm = try! Realm()

    // Realm에서 데이터를 가져와 담을 공간 생성
    var realmList           : Results<MyDailyTable>!    // 일정 저장 테이블
    var realmCategoryList   : Results<MyCategoryTable>! // 카테고리 저장 테이블
    var realmSetting        : MySettingTable!
    
    // viewMode
    var viewMode : viewScreenType = .monthView
    
    let plist = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateVersionCheck()
        checkReviewCount()
        
        // 알아보기
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: NSNotification.Name("refreshData"), object: nil)
        
        myDayTable.delegate = self
        myDayTable.dataSource = self
        
        myCalendar.delegate = self
        myCalendar.dataSource = self
        
        databaseSetting()
        calendarAppearanceSetting()
        viewSetting()
        dailyAlertSetting()
        GADBannerFunction()
        
        // swift attributeText color, font, bold
//        let attributedString = NSMutableAttributedString(string: allDayViewButton.titleLabel!.text!)
//        attributedString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.blue, range: (allDayViewButton.titleLabel!.text! as NSString).range(of:"일정"))
//        allDayViewButton.titleLabel!.attributedText = attributedString
    }
    
    
    // MARK: - 데일리 알람
    func dailyAlertSetting() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyAlertID"])
        
        // Notification 3 - 로컬 알림에 보낼 메시지 생성
        let content = UNMutableNotificationContent()
        content.title = "[오늘Do 알림]"
        content.body = "하루가 시작되었습니다 :)\n새로운 일정을 확인해보는 것이 어떨까요?"
        
        // Notification 4-2. 로컬 알림의 전송 시점 생성(캘린더)
        //캘린더를 활용한 로컬 알림 ex. 매일 오전 00:00:00
        var cal = DateComponents()
        cal.hour    = 7
        cal.minute  = 0
        cal.second  = 0
        
        let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: cal, repeats: true)
            
        // Notification 5. 로컬 알림을 요청할 준비 - (중요) identifier
        // identifier : 로컬 알림의 고유 이름, 최대 64개까지 보낼 수 있음
        let request = UNNotificationRequest(identifier: "dailyAlertID", content: content, trigger: calendarTrigger)
            
        // Notification 6. 로컬 알림 최종 보내기
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
    
    // MARK: - 업데이트 체크
    func updateVersionCheck() {
        
        // 현재 앱의 버전 String
        let presentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String

        if let presentVersion = presentVersion {
            let identifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String
            let appStoreVersionURL = "http://itunes.apple.com/lookup?bundleId=\(identifier!)&country=kr"

            AF.request(appStoreVersionURL, method: .get).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    
                    // 현재 앱의 버전 Double
                    let changeVersion = Double(presentVersion)!
                    // 앱 스토어에 등록된 앱의 버전 가져옴
                    let appVersionDouble = Double(json["results"][0]["version"].stringValue)!
                    
                    if changeVersion < appVersionDouble {
                        let updateAlert = UIAlertController(title: "알림 메세지", message: "새로운 버전이 나왔습니다.\n최신 버전으로 업데이트 하세요.", preferredStyle: .alert)

                        updateAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: { ACTION in
                            
                            // 확인 눌렀을 때 appStore로 이동시킴
                            let appStoreURL = URL(string: SaveURL.todayDoAppstoreURL)
                            
                            UIApplication.shared.open(appStoreURL!, options: [:], completionHandler: { ACTION in
                                exit(0)
                            })
                        }))

                        self.present(updateAlert, animated: true)
                    }
                    
                case .failure(let error):
                    print(error)
                }
            }
        }
        
    }
    
    // MARK: - 구글 광고 추가
    func GADBannerFunction() {
        // 출시 직전 Change
        // Test 광고 ID
//        bannerView.adUnitID = SaveURL.googleADtestID
        
        // 실제 광고 ID
        bannerView.adUnitID = SaveURL.googleADMyID
        bannerView.rootViewController = self
        bannerView.delegate = self
        bannerView.load(GADRequest())
    }
    
    // MARK: - 공휴일 가져오는 함수
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
            try! self.realm.write {
                updateObject?.holidayList.append(requestYear)
            }
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
    
    // MARK: date formatter
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        formatter.locale = Locale(identifier:"ko_KR")
        formatter.timeZone = TimeZone(abbreviation: "KST")
//        formatter.locale = Locale.current
//        formatter.timeZone = TimeZone.current
        return formatter
    }()
    
    // MARK: - 화면을 불러올때마다 실행하는 부분
    override func viewWillAppear(_ animated: Bool) {
        dateSettingFunc()
        
        self.myDayTable.reloadData()
        self.myCalendar.reloadData()
    }
    
    // 일반: green, 중요: red, 행사: blue, 약속: pink
    // MARK: 캘린더에 표시할 데이터 setting
    func dateSettingFunc() {
        monthDailyTable.removeAll()
        monthCompleteTable.removeAll()
        calendarData.removeAll()
        
        // 색상 수정 시 적용
        self.myCalendar.appearance.selectionColor = rgbPalette[realmSetting.indexSelectColor]
        self.myCalendar.appearance.todayColor = rgbPalette[realmSetting.indexTodayColor]
        self.myCalendar.appearance.titleTodayColor = .white
        
        var calendarIndex : Int = 0

        for row in 0..<realmList.count {
            let realmDate : Date = realmList[row].dailyDate
//            print(realmList[row].dailyComplete)
//            print("realmDate = \(realmDate)")
            let startDate : Date = myCalendar.currentPage
//            print("startDate = \(startDate)")
            
            var endDateString : String
            let currentDate = myCalendar.currentPage
            if currentDate.month == 12 {
                endDateString = "\(currentDate.year+1)-1-\(currentDate.day)"
            } else {
                endDateString = "\(currentDate.year)-\(currentDate.month+1)-\(currentDate.day)"
            }
            let endDate = dateFormatter.date(from: endDateString)
//            print("endDate = \(endDate!)")
            
            if (realmDate >= startDate) && (realmDate < endDate!) {
                if realmList[row].dailyComplete == false {
                    monthDailyTable.append(realmList[row])
                } else if realmList[row].dailyComplete == true {
                    monthCompleteTable.append(realmList[row])
                }
            }
        }
        
        for row in 0..<monthDailyTable.count {
            let rowIndexDate = dateFormatter.string(from: monthDailyTable[row].dailyDate)

            // 캘린더에 표시할 배열의 첫번째인지?
            if calendarData.count == 0 {
                let temp : DateColorClass = DateColorClass()

                temp.date = rowIndexDate
                temp.dateCount += 1
                
                if monthDailyTable[row].dailyIsHoliday != 0 {
                    temp.colorArr.append(rgbPalette[realmSetting.indexHoliday])
                } else { temp.colorArr.append(rgbPalette[realmCategoryList[monthDailyTable[row].dailyCategory].categoryColor])
                }
                
                temp.writeNum.append(monthDailyTable[row].dailyNum)

                calendarData.append(temp)
            } else {    // 첫번째가 아니라면?
                let compareDate = rowIndexDate
                var compareColor : UIColor
                let index = monthDailyTable[row].dailyCategory
                
                if monthDailyTable[row].dailyIsHoliday != 0 {
                    compareColor = rgbPalette[realmSetting.indexHoliday]
                } else {
                    compareColor = rgbPalette[realmCategoryList[index].categoryColor]
                }

                // 캘린더 배열에 같은 날짜가 있다면 해당 row에 색깔 추가
                if calendarData[calendarIndex].date == compareDate {
                    // 같은 색깔이 있지 않다면 추가, 없다면 패스
                    if !(calendarData[calendarIndex].colorArr.contains(compareColor)) {
                        calendarData[calendarIndex].colorArr.append(compareColor)
                    }
                    calendarData[calendarIndex].dateCount += 1  // date 갯수, 글번호 추가
                    calendarData[calendarIndex].writeNum.append(monthDailyTable[row].dailyNum)
                } else { // 캘린더 배열에 같은 날짜가 없다면?
                    calendarIndex += 1
                    let temp : DateColorClass = DateColorClass()

                    temp.date = compareDate
                    temp.dateCount += 1

                    temp.colorArr.append(compareColor)
                    temp.writeNum.append(monthDailyTable[row].dailyNum)
                    calendarData.append(temp)
                }
            }
        }
        
        // dayView 모드인 경우 Array, Count 새로 세팅
        if viewMode == .dayView {
            let selectDate = plist.string(forKey: "selectDate")
            _ = calendarData.map {
                if $0.date == selectDate {
                    plist.set($0.dateCount, forKey: "selectCount")
                    plist.set($0.writeNum, forKey: "selectArray")
                }
            }
        }
        
        // Badge 설정
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    @objc func refreshData() {
        dateSettingFunc()
        
        myCalendar.setCurrentPage(Date(), animated: true)
        
        myDayTable.reloadData()
        myCalendar.reloadData()
    }
    
    // MARK: - Database(realm) 세팅
    func databaseSetting() {
        realmList = realm.objects(MyDailyTable.self).sorted(byKeyPath: "dailyDate", ascending: true)
        realmCategoryList = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
        realmSetting = realm.objects(MySettingTable.self).first

        if realmCategoryList.count == 0 {
            let basicTitle = ["일반", "중요", "행사", "약속"]
            let basicContext = ["기본", "기본", "기본", "기본"]
            let basicColor : [Int] = [Int.random(in: 0..<63), Int.random(in: 0..<63), Int.random(in: 0..<63), Int.random(in: 0..<63)]

            for row in 0...3 {
                let tempCategory = MyCategoryTable()
                tempCategory.categoryNum = row
                tempCategory.categoryIndex = row
                tempCategory.categoryTitle = basicTitle[row]
                tempCategory.categoryContext = basicContext[row]
                tempCategory.categoryColor = basicColor[row]
                try! realm.write {
                    realm.add(tempCategory)
                }
            }
        }
        
        if realmSetting.holidayList.contains(myCalendar.currentPage.year) {
//            print("\(realmSetting.holidayList.contains(myCalendar.currentPage.year)) Exist")
        } else {
//            print("\(myCalendar.currentPage.year) is Not Exist")
            requestHoliday(requestYear: myCalendar.currentPage.year)
        }
    }
    
    // 전체보기 선택했을 경우
    @IBAction func clickedAllDayView(_ sender: UIButton) {
        viewMode = .monthView

        self.myCalendar.reloadData()
        self.myDayTable.reloadData()
    }
    
    // MARK: 메인 뷰 세팅
    func viewSetting() {
        let listButton = UIBarButtonItem(image: UIImage(named: "list"), style: .plain, target: self, action: #selector(clickListView))
        listButton.tintColor = .black
        
        let registerButton = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(clickRegister))
        registerButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItems = [registerButton, listButton]
        
        allDayViewButton.setTitleColor(.black, for: .normal)
        allDayViewButton.titleLabel?.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 20)
        allDayViewButton.setTitle("전체 일정 보기", for: .normal)
//        allDayViewButton.backgroundColor = UIColor().customPink
        allDayViewButton.backgroundColor = .white
        
        completeViewButton.setTitleColor(.black, for: .normal)
        completeViewButton.titleLabel?.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 20)
        completeViewButton.setTitle("완료된 일정 보기", for: .normal)
//        completeViewButton.backgroundColor = UIColor().customPink
        completeViewButton.backgroundColor = .white
        completeViewButton.addTarget(self, action: #selector(clickedCompleteView), for: .touchUpInside)
        
        
        for item in [allDayViewButton, completeViewButton] {
            item?.layer.borderColor = UIColor.lightGray.cgColor
            item?.layer.borderWidth = 0.5
        }
        
//        self.navigationController?.navigationBar.barTintColor = UIColor().customPinkBar
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        self.title = ""
    }
    
    // MARK: complete 버튼 클릭 시
    @objc func clickedCompleteView(_ sender: UIButton) {
        
        sender.isSelected = !sender.isSelected
        sender.tintColor = .clear
        
        if sender.isSelected {
            sender.setTitleColor(.white, for: .normal)
            sender.backgroundColor = .lightGray
        } else {
            sender.setTitleColor(.black, for: .normal)
            sender.backgroundColor = .white
        }
        
        self.myCalendar.reloadData()
        self.myDayTable.reloadData()
    }
   
    // MARK: - 일정 모음 버튼 클릭
    @objc func clickListView() {
        let moveView = self.storyboard?.instantiateViewController(withIdentifier: "DoListTableViewController") as! DoListTableViewController

        let navi = UINavigationController(rootViewController: moveView)
        navi.modalPresentationStyle = .fullScreen
        navi.modalTransitionStyle = .crossDissolve
        
        self.present(navi, animated: true, completion: nil)
    }
    
    // MARK: - 일정 추가 버튼 클릭
    @objc func clickRegister(_ sender: UIBarButtonItem) {
        let moveView = self.storyboard?.instantiateViewController(withIdentifier: "RegisterTableViewController") as! RegisterTableViewController

        moveView.registerType = .dailyInsert
        moveView.selectDate = dateFormatter.string(from: myCalendar.selectedDate ?? Date())
        
        let navi = UINavigationController(rootViewController: moveView)
        navi.modalPresentationStyle = .fullScreen
        
        self.present(navi, animated: true, completion: nil)
    }
    
    // MARK: - 캘린더 부분 함수
    func calendarAppearanceSetting() {
        self.myCalendar.locale = Locale(identifier:"ko_KR")
        
        self.myCalendar.appearance.weekdayTextColor = UIColor.black
        self.myCalendar.appearance.weekdayFont = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 14)
        self.myCalendar.appearance.caseOptions = .weekdayUsesSingleUpperCase
        
        self.myCalendar.appearance.headerTitleColor = UIColor.black
        self.myCalendar.appearance.headerTitleFont = fontCoreDreamLight(fontSize: 22)//fontCoreDreamHeavy(fontSize: 22)
            self.myCalendar.appearance.headerDateFormat = "yyyy. MM"
        self.myCalendar.headerHeight = 60
        self.myCalendar.appearance.headerMinimumDissolvedAlpha = 0.1
        
        self.myCalendar.placeholderType = .none
        
        self.myCalendar.appearance.titleFont = fontCoreDreamLight(fontSize: 16) // 날짜 크기
        
        self.myCalendar.calendarHeaderView.backgroundColor = .white
        self.myCalendar.calendarWeekdayView.backgroundColor = .white
    }
    
    
    // MARK: 각 날짜에 점 갯수 표시
    func calendar(_ calendar: FSCalendar, numberOfEventsFor date: Date) -> Int {
        let dateString = self.dateFormatter.string(from: date)
        
        if monthDailyTable.count > 0 {
            for row in 0..<calendarData.count {
                if calendarData[row].date == dateString {
                    return calendarData[row].colorArr.count
                }
            }
        }
        return 0
    }
    
    // MARK: 날짜 점 색깔
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, eventDefaultColorsFor date: Date) -> [UIColor]? {
        let key = self.dateFormatter.string(from: date)
        appearance.eventSelectionColor = .purple
        
        for row in 0..<calendarData.count {
            if calendarData[row].date == key {
                return calendarData[row].colorArr
            }
        }
        return nil
    }
    
    // MARK: 날짜 선택했을 때 method
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        var findBool : Bool = false
        let formatDate = dateFormatter.string(from: date)
        
        viewMode = .dayView
        
        plist.set(formatDate, forKey: "selectDate")
//        plist.set(false, forKey: "pageMove")
        
        _ = calendarData.map {
            if $0.date == formatDate {
                plist.set($0.dateCount, forKey: "selectCount")
                plist.set($0.writeNum, forKey: "selectArray")
//                print("calendar : \($0.date!)")
//                print("calendar : \($0.dateCount)")
                findBool = true
            }
        }
        if !findBool {
            plist.set(0, forKey: "selectCount")
        }
        self.myDayTable.reloadData()
    }
    
    // MARK: 달력 이동했을 때 slide
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        if !(realmSetting.holidayList.contains(myCalendar.currentPage.year)) {
            // 해당 년도 공휴일이 없을 경우
            requestHoliday(requestYear: myCalendar.currentPage.year)
        }
        
        // 문자열 자르기 해서 앞에 4자리가 같으면 ㄱㄱ
        let currentDate = calendar.currentPage
        plist.set("\(currentDate.year)-\(currentDate.month)", forKey: "presentDate")
//        plist.set(true, forKey: "pageMove")
        
        viewMode = .monthView
        
        dateSettingFunc()
        self.myCalendar.reloadData()
        self.myDayTable.reloadData()
        
        myCalendar.select(currentDate)
   }
    
    // MARK: 달력 day title 색깔
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        if calendar.today == date {
            return .white
        }
        
        for item in monthDailyTable {
            if (item.dailyDate == date) && (item.dailyIsHoliday == 1) {
                return rgbPalette[realmSetting.indexHoliday]
            }
        }
        
        for item in monthCompleteTable {
            if (item.dailyDate == date) && (item.dailyIsHoliday == 1) {
                return rgbPalette[realmSetting.indexHoliday]
            }
        }
        
        if (date.weekday % 7) == 1 {
            if calendar.today == date {
                return .white
            } else {
                return rgbPalette[realmSetting.indexHoliday]
            }
        } else if (date.weekday % 7) == 0 {
            if calendar.today == date {
                return .white
            } else {
                return rgbPalette[realmSetting.indexSaturday]
            }
        }
        return rgbPalette[realmSetting.indexDefault]
    }

    // MARK: - 테이블 뷰 설정
    // MARK: cell 갯수
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            let limitCount = realmSetting.dailyLimitCount
            
            switch viewMode {
            case .monthView:
                if monthDailyTable.count > limitCount {
                    return limitCount
                } else {
                    return monthDailyTable.count
                }
            case .dayView:
                // 선택한 날짜의 일정 갯수
                let viewCount = plist.integer(forKey: "selectCount")
                if viewCount > limitCount {
                    return limitCount
                } else {
                    return viewCount
                }
            }
        } else if section == 1 {
            if completeViewButton.isSelected {
                return monthCompleteTable.count
            } else {
                return 0
            }
        }
        return 0
    }
    
    // MARK: 일정 list cell 구성
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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
            switch viewMode {
                case .monthView:
                    let dailyTable = monthDailyTable[indexPath.row]
                    cell.titleLabel.text = dailyTable.dailyTitle
                    
                    // Obtain the date according to the format.
                    let selectedDate: String = dateFormatter.string(from: dailyTable.dailyDate)
                    cell.dateLabel.text = "\(selectedDate)"
                    
                    let selectTime: String = timeFormatter.string(from: dailyTable.dailyDate)
                    cell.timeLabel.text = "\(selectTime)"
    //                cell.categoryColor.backgroundColor = rgbPalette[dailyTable.dailyCategory]
                    
                    cell.dateNum.text = "\(dailyTable.dailyNum)"
                    
                    if monthDailyTable[indexPath.row].dailyIsHoliday != 0 {
                        cell.selectionStyle = .none
                        cell.categoryColor.backgroundColor = rgbPalette[realmSetting.indexHoliday]
                    } else {
                        cell.selectionStyle = .default
                        cell.categoryColor.backgroundColor = rgbPalette[realmCategoryList[dailyTable.dailyCategory].categoryColor]
                    }
                    return cell
                case .dayView:
                    let selectArray = (plist.array(forKey: "selectArray") as? [Int])!
        //            print("test : \(selectArray)")
        //            print(selectArray[indexPath.row])
                    _ = monthDailyTable.map {
                        if $0.dailyNum == selectArray[indexPath.row] {
                            cell.titleLabel.text = $0.dailyTitle
                            
                            // Obtain the date according to the format.
                            let selectedDate: String = dateFormatter.string(from: $0.dailyDate)
                            let selectedTime: String = timeFormatter.string(from: $0.dailyDate)
                            
                            cell.dateLabel.text = "\(selectedDate)"
                            cell.timeLabel.text = "\(selectedTime)"
                            cell.dateNum.text = "\($0.dailyNum)"
                            
                            if $0.dailyIsHoliday != 0 {
                                cell.selectionStyle = .none
                                cell.categoryColor.backgroundColor = rgbPalette[realmSetting.indexHoliday]
                            } else {
                                cell.selectionStyle = .default
                                cell.categoryColor.backgroundColor = rgbPalette[realmCategoryList[$0.dailyCategory].categoryColor]
                            }
                        }
                    }
                    return cell
            }
        } else if indexPath.section == 1 {
            cell.backgroundColor = UIColor().customGray
            cell.layer.borderColor = UIColor.white.cgColor
            cell.dateButton.tintColor = .white
            
            let dailyTable = monthCompleteTable[indexPath.row]
            cell.titleLabel.text = dailyTable.dailyTitle
            
            // Obtain the date according to the format.
            let selectedDate: String = dateFormatter.string(from: dailyTable.dailyDate)
            let selectedTime: String = timeFormatter.string(from: dailyTable.dailyDate)
                    
            cell.dateLabel.text = "\(selectedDate)"
            cell.timeLabel.text = "\(selectedTime)"
            
            cell.dateNum.text = "\(dailyTable.dailyNum)"
            
            if monthCompleteTable[indexPath.row].dailyIsHoliday != 0 {
                cell.selectionStyle = .none
                cell.categoryColor.backgroundColor = rgbPalette[realmSetting.indexHoliday]
            } else {
                cell.selectionStyle = .default
                cell.categoryColor.backgroundColor = rgbPalette[realmCategoryList[dailyTable.dailyCategory].categoryColor]
            }
            return cell
        }
        return cell
    }
    
    // header title
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "일정"
        } else if section == 1 {
            return "완료된 일정"
        }
        return ""
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if monthCompleteTable.count != 0 && completeViewButton.isSelected {
            return 2
        } else {
            return 1
        }
    }
    
    // cell height
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    // MARK: cell 선택했을 때
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
        
        if cell.selectionStyle != .none {
            let uv = self.storyboard!.instantiateViewController(withIdentifier: "RegisterTableViewController") as! RegisterTableViewController
            
            uv.modalPresentationStyle = .fullScreen
            uv.registerType = .dailyUpdate
            uv.dailyNumber  = Int(cell.dateNum.text!)!
            
            self.navigationController?.pushViewController(uv, animated: true)
        }
    }
    
    @IBAction func clickedMenuButton(_ sender: UIBarButtonItem) {
        let uv = (self.storyboard?.instantiateViewController(withIdentifier: "SideMenuNavigationController"))!
        
        self.present(uv, animated: true, completion: nil)
    }
    
    // MARK: TableView trailing 오른쪽
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        
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

            // 2. tableview reload
            if self.viewMode == .dayView {
                self.plist.set(0, forKey: "selectCount")
            }
            self.dateSettingFunc()
            self.myDayTable.reloadData()
            self.myCalendar.reloadData()
        }

        return UISwipeActionsConfiguration(actions: [deleteButton])
    }
    
    // MARK: leading 왼쪽
    func tableView(_ tableView: UITableView, leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {

        if indexPath.section == 0 {
            let completeButton = UIContextualAction(style: .normal, title: "완료") { (action : UIContextualAction, view : UIView, success : (Bool) -> Void) in
                
                let cell = tableView.cellForRow(at: indexPath) as! MainTableViewCell
                let dailyNum = Int(cell.dateNum.text!)!
                
                let editObject = self.realm.objects(MyDailyTable.self).filter("dailyNum == \(dailyNum)").first
                
                try! self.realm.write {
                    editObject?.dailyComplete = true
                }
                
                if self.viewMode == .dayView {
                    self.plist.set(0, forKey: "selectCount")
                }
                self.dateSettingFunc()
                self.myDayTable.reloadData()
                self.myCalendar.reloadData()
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
                
                if self.viewMode == .dayView {
                    self.plist.set(0, forKey: "selectCount")
                }
                self.dateSettingFunc()
                self.myDayTable.reloadData()
                self.myCalendar.reloadData()
            }
            completeButton.backgroundColor = .darkGray
            return UISwipeActionsConfiguration(actions: [completeButton])
        }
    }
}

// MARK: - 광고 Delegate
extension MainViewController: GADBannerViewDelegate {
    /// Tells the delegate an ad request loaded an ad.
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
        print("배너 광고 가져옴 adViewDidReceiveAd")
    }

    /// Tells the delegate an ad request failed.
    func adView(_ bannerView: GADBannerView,
        didFailToReceiveAdWithError error: GADRequestError) {
        print("배너 광고 못 가져옴 adView:didFailToReceiveAdWithError: \(error.localizedDescription)")
//        bannerView.load(GADRequest())
    }

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
    func adViewWillPresentScreen(_ bannerView: GADBannerView) {
        print("adViewWillPresentScreen")
    }

    /// Tells the delegate that the full-screen view will be dismissed.
    func adViewWillDismissScreen(_ bannerView: GADBannerView) {
        print("adViewWillDismissScreen")
    }

    /// Tells the delegate that the full-screen view has been dismissed.
    func adViewDidDismissScreen(_ bannerView: GADBannerView) {
        print("adViewDidDismissScreen")
    }

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
    func adViewWillLeaveApplication(_ bannerView: GADBannerView) {
        print("광고 클릭 adViewWillLeaveApplication")
        bannerView.load(GADRequest())
    }
}

// MARK: - 평가 및 리뷰 요청
extension MainViewController {
    func appParityRequest() {
        if #available(iOS 10.3, *) {
            SKStoreReviewController.requestReview()
        } else {
            // Fallback on earlier versions
        }
    }
    
    // 리뷰 카운트
    func checkReviewCount() {
        let plist = UserDefaults.standard
        let reviewCount = plist.integer(forKey: "requestReviewCount")
        if reviewCount == SaveAppSetting.reviewCountLimit {
            plist.set(1, forKey: "requestReviewCount")
            self.appParityRequest()
        } else {
            let settingCount = reviewCount + 1
            plist.set(settingCount, forKey: "requestReviewCount")
        }
    }
}
