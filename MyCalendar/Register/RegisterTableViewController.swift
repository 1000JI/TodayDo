//
//  RegisterTableViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift
import SnapKit
import YPImagePicker

class RegisterTableViewController: UITableViewController {

    // Realm에 접근하겠다는 트리거 생성, Realm에 변화가 있다면 무조건 거쳐감!
    let realm = try! Realm()

    // Realm에서 데이터를 가져와 담을 공간 생성
    var realmList           : Results<MyDailyTable>!    // 일정 저장 테이블
    var realmCategoryList   : Results<MyCategoryTable>! // 카테고리 저장 테이블
    
    @IBOutlet var titleTextfield: UITextField!
    @IBOutlet var dateSelectButton: UIButton!
    @IBOutlet var categorySeg: UISegmentedControl!
    @IBOutlet var contentsTextview: UITextView!
    @IBOutlet var contentsImage: UIImageView!
    @IBOutlet var registerPicButton: UIButton!
    @IBOutlet var alertSettingButton: UIButton!
    @IBOutlet var alertOnOffSwitch: UISwitch!
    
    @IBOutlet var lbTitle: UILabel!
    @IBOutlet var lbDate: UILabel!
    @IBOutlet var lbCategory: UILabel!
    @IBOutlet var lbContents: UILabel!
    
    // Date
    var selectDate        : String?
    
    var registerType        : registerScreenType        = .dailyInsert
    var dailyNumber         : Int                       = 0
    
    
    // 알람 세팅 문자
    let alertSetArray = ["일정 정각", "5분 전", "10분 전", "15분 전", "30분 전", "1시간 전", "2시간 전", "1일 전", "2일 전", "1주 전"]
    
    @IBAction func swipeBack(_ sender: UISwipeGestureRecognizer) {
        if registerType == .dailyInsert {
            self.dismiss(animated: true, completion: nil)
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(endEditing)))
        
        realmCategoryList = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
        
        borderSetting()
        viewSetting()
    }
    
    // 키보드 내리기
    @objc func endEditing(){
        self.view.endEditing(true)
    }
    
    // MARK: date formatter
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d HH:mm"
        formatter.locale = Locale(identifier:"ko_KR")
        return formatter
    }()
    
    // MARK: - Date 버튼 선택 함수
    @IBAction func clickedDateSelect(_ sender: UIButton) {
        let datePicker = UIDatePicker()
        datePicker.datePickerMode = .dateAndTime
        datePicker.minuteInterval = 10
        datePicker.locale = Locale(identifier:"ko_KR")
        datePicker.timeZone = TimeZone(abbreviation: "KST")
        datePicker.date = dateFormatter.date(from: self.dateSelectButton.titleLabel!.text!)!

        let alert = UIAlertController(title: "\n\n\n\n\n\n\n\n\n\n\n", message: nil, preferredStyle: .actionSheet)
        alert.view.addSubview(datePicker)

        datePicker.snp.makeConstraints { (make) in
                make.centerX.equalTo(alert.view)
                make.top.equalTo(alert.view).offset(8)
        }

        let ok = UIAlertAction(title: "확인", style: .default) { (action) in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-M-d HH:mm"
            dateFormatter.locale = Locale(identifier:"ko_KR")
            dateFormatter.timeZone = TimeZone(abbreviation: "KST")
            self.dateSelectButton.setTitle("\(self.dateFormatter.string(from: datePicker.date))", for: .normal)
        }

        let cancel = UIAlertAction(title: "취소", style: .cancel, handler: nil)

        alert.addAction(ok)
        alert.addAction(cancel)

        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - View 구성
    func viewSetting() {
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(named: "save"), style: .plain, target: self, action: #selector(saveRightBarItemClicked))
        self.navigationItem.rightBarButtonItem?.tintColor = .black
//        self.navigationController?.navigationBar.barTintColor = UIColor().customPinkBar
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        
        // Font & Size Setting
        titleTextfield.font = fontCoreDreamLight(fontSize: 17)
        
        dateSelectButton.titleLabel?.font = fontCoreDreamLight(fontSize: 17)
        dateSelectButton.setTitleColor(.black, for: .normal)
        
        dateSelectButton.setTitle(self.dateFormatter.string(from: Date()), for: .normal)
        
        contentsTextview.font = fontCoreDreamLight(fontSize: 15)
        
        categorySeg.removeAllSegments()
        for row in 0..<realmCategoryList.count {
            categorySeg.insertSegment(withTitle: realmCategoryList[row].categoryTitle, at: row, animated: true)
            categorySeg.addTarget(self, action: #selector(segmentedControlValueChanged), for: .valueChanged)
        }
        
        registerPicButton.setImage(UIImage(named: "plus"), for: .normal)
        registerPicButton.tintColor = .black
        contentsImage.image = nil
        
        alertSettingButton.addTarget(self, action: #selector(alertDatePicker), for: .touchUpInside)
        alertSettingButton.isEnabled = false
        alertSettingButton.setTitle(alertSetArray[0], for: .normal)
        alertSettingButton.titleLabel?.font = fontCoreDreamLight(fontSize: 15)
        alertSettingButton.setTitleColor(.lightGray, for: .normal)
        
        alertOnOffSwitch.isOn = false
        alertOnOffSwitch.addTarget(self, action: #selector(alertOnOffValueChanged), for: .valueChanged)
        
        //---------------------------------
        
        switch registerType {
        case .dailyInsert:
            self.title = "일정 등록"
            
            categorySeg.selectedSegmentIndex = 0
            if #available(iOS 13.0, *) {
                categorySeg.selectedSegmentTintColor = rgbPalette[realmCategoryList[0].categoryColor]
            } else {
                categorySeg.tintColor = rgbPalette[realmCategoryList[0].categoryColor]
            }
            
            dateSelectButton.setTitle("\(selectDate!) 00:00", for: .normal)
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(leftBarItemClicked))
            self.navigationItem.leftBarButtonItem?.tintColor = .black
        case .dailyUpdate:
            self.title = "일정 수정"
            let getUpdateDaily = realm.objects(MyDailyTable.self).filter("dailyNum == \(self.dailyNumber)")
            
            for row in 0..<getUpdateDaily.count {
                let findData = getUpdateDaily[row]
                titleTextfield.text = findData.dailyTitle
                dateSelectButton.setTitle(self.dateFormatter.string(from: findData.dailyDate), for: .normal)
                categorySeg.selectedSegmentIndex = findData.dailyCategory
                
                if findData.dailyAlertOn {
                    alertOnOffSwitch.isOn = true
                    alertSettingButton.isEnabled = true
                    alertSettingButton.setTitleColor(.black, for: .normal)
                    alertSettingButton.setTitle(findData.dailyAlertDate, for: .normal)
                }
                
                if #available(iOS 13.0, *) {
                    categorySeg.selectedSegmentTintColor = rgbPalette[realmCategoryList[findData.dailyCategory].categoryColor]
                } else {
                    categorySeg.tintColor = rgbPalette[realmCategoryList[0].categoryColor]
                }
                
                contentsTextview.text = findData.dailyContents
    //            contentsImage.image
                
                // -------------------
                
                //도큐먼트에 저장된 사진(ex. 18.jpg)을 Realm Data에 맞게 보여주기
                //1. 파일 시스템 접근
                let fileManager = FileManager.default
                
                //2. 도큐먼트 경로에 맞는 이미지 파일 이름 가져오기
                let imagePAth = (getDirectoryPath() as NSString).appendingPathComponent("\(findData.dailyNum).png")
                
                //3. 이미지 파일이 존재할 경우, cell의 photoImageView에 해당 이미지 보여주기
                if fileManager.fileExists(atPath: imagePAth){
                    self.contentsImage.image = UIImage(contentsOfFile: imagePAth)
                    self.registerPicButton.setImage(nil, for: .normal)
                }
                
                self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(leftBarItemClicked2))
                self.navigationItem.leftBarButtonItem?.tintColor = .black
            }
        }
    }
    
    // MARK: 알람 시간 버튼 눌렀을 경우
    @objc func alertDatePicker(_ sender: UIButton) {
        let alert = UIAlertController(title: "알람 설정", message: "알람이 울릴 시간을 선택하세요.", preferredStyle: .actionSheet)
        
        for setTitle in alertSetArray {
            alert.addAction(UIAlertAction(title: setTitle, style: .default, handler: { ACTION in
                sender.setTitle(self.alertSetArray[self.alertSetArray.firstIndex(of: ACTION.title!)!], for: .normal)
                
            }))
        }
        
        let cancleAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(cancleAction)
        self.present(alert, animated: true)
    }
    
    // MARK: 알람 기능 스위치 변경했을 때
    @objc func alertOnOffValueChanged(_ sender: UISwitch) {
        if sender.isOn {
            alertSettingButton.isEnabled = true
//            alertSettingButton.setTitle(dateSelectButton.titleLabel?.text, for: .normal)
            alertSettingButton.setTitleColor(.black, for: .normal)
        } else {
            alertSettingButton.isEnabled = false
            alertSettingButton.setTitleColor(.lightGray, for: .normal)
        }
    }
    
    @objc func segmentedControlValueChanged(segment: UISegmentedControl) {
        let categoryColorSet = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
        let selectCategoryColor = rgbPalette[categoryColorSet[segment.selectedSegmentIndex].categoryColor]
        
        if #available(iOS 13.0, *) {
            segment.selectedSegmentTintColor = selectCategoryColor
        } else {
            segment.tintColor = selectCategoryColor
        }
    }
    
    @objc func leftBarItemClicked() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func leftBarItemClicked2() {
        self.navigationController?.popViewController(animated: true)
    }
    
    // MARK: - 저장 버튼 눌렀을 때
    @objc func saveRightBarItemClicked() {
        if titleTextfield.text == "" {
            // Alert
            // 1. 알람창 생성(alert, actionsheet)
            let alert = UIAlertController(title: "일정 등록 실패", message: "제목을 입력해주세요.", preferredStyle: .alert)
            
            // 2. 버튼 생성
            //  style : .default(기본), .cancel(별도 구성), destructive(빨간 글씨)
            let okButton = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            
            // 3. 알림창에 버튼 추가
            alert.addAction(okButton)
            
            // 4. 알림창 표출
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        switch registerType {
        case .dailyInsert:
            // Realm Create 1. 빈 행
            let writeDaily : MyDailyTable = MyDailyTable()
            let primaryKey              = createNewID()
            writeDaily.dailyNum         = primaryKey
            writeDaily.dailyTitle       = titleTextfield.text!
            writeDaily.dailyDate        = self.dateFormatter.date(from: (dateSelectButton.titleLabel!.text!))!
            writeDaily.dailyCategory    = categorySeg.selectedSegmentIndex
            writeDaily.dailyContents    = contentsTextview.text
            writeDaily.dailyComplete    = false
            writeDaily.dailyAlertOn     = alertOnOffSwitch.isOn
            
            if alertOnOffSwitch.isOn {
                writeDaily.dailyAlertDate = alertSettingButton.titleLabel!.text!
                
                // Notification 3 - 로컬 알림에 보낼 메시지 생성
                let content = UNMutableNotificationContent()
                content.title       = writeDaily.dailyTitle
                content.subtitle    = dateSelectButton.titleLabel!.text!
                content.body        = writeDaily.dailyContents
//                content.badge       = UIApplication.shared.applicationIconBadgeNumber + 1 as NSNumber
                
//                print("일정 시간 : \(dateFormatter.string(from: writeDaily.dailyDate))")
//                print("\(writeDaily.dailyDate - 3600)")
                
                var alertTime = Date()
                
                // 각 알람 시간 선택 했을 때 액션
                switch self.alertSetArray.firstIndex(of: writeDaily.dailyAlertDate) {
                case 0:
//                    print("일정 정각")
                    alertTime = writeDaily.dailyDate
                case 1:
//                    print("5분 전")
                    alertTime = writeDaily.dailyDate - (5 * 60)
                case 2:
//                    print("10분 전")
                    alertTime = writeDaily.dailyDate - (10 * 60)
                case 3:
//                    print("15분 전")
                    alertTime = writeDaily.dailyDate - (15 * 60)
                case 4:
//                    print("30분 전")
                    alertTime = writeDaily.dailyDate - (30 * 60)
                case 5:
//                    print("1시간 전")
                    alertTime = writeDaily.dailyDate - (60 * 60)
                case 6:
//                    print("2시간 전")
                    alertTime = writeDaily.dailyDate - (120 * 60)
                case 7:
//                    print("1일 전")
                    alertTime = writeDaily.dailyDate - (24 * 60 * 60)
                case 8:
//                    print("2일 전")
                    alertTime = writeDaily.dailyDate - (48 * 60 * 60)
                case 9:
//                    print("1주 전")
                    alertTime = writeDaily.dailyDate - (7 * 24 * 60 * 60)
                default:
                    print("default")
                }
                
//                print("알람 시간 : \(dateFormatter.string(from: alertTime))")
                
                // Notification 4-2. 로컬 알림의 전송 시점 생성(캘린더)
                //캘린더를 활용한 로컬 알림 ex. 3/1 오후 10시 정각
                var cal = DateComponents()
                cal.year    = alertTime.year
                cal.month   = alertTime.month
                cal.day     = alertTime.day
                cal.hour    = alertTime.hour
                cal.minute  = alertTime.minute
                cal.second  = alertTime.second
                
                let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: cal, repeats: false)
                
                // Notification 5. 로컬 알림을 요청할 준비 - (중요) identifier
                // identifier : 로컬 알림의 고유 이름, 최대 64개까지 보낼 수 있음
                let request = UNNotificationRequest(identifier: "\(writeDaily.dailyNum)", content: content, trigger: calendarTrigger)
                
                // Notification 6. 로컬 알림 최종 보내기
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            } else {
                writeDaily.dailyAlertDate = ""
            }

            if contentsImage.image != nil {
                savePhotosToDocumentDirectory(image: contentsImage.image!, fileName: "\(primaryKey).png")
            }
            
            // Realm Table에 최종적으로 추가
            try! realm.write {
                realm.add(writeDaily)
            }
            
            self.dismiss(animated: true, completion: nil)
        case .dailyUpdate:
            let primaryKey = self.dailyNumber
            
            let updateObject = self.realm.objects(MyDailyTable.self).filter("dailyNum == \(self.dailyNumber)").first
            
            try! self.realm.write {
                updateObject?.dailyTitle = titleTextfield.text!
                updateObject?.dailyTitle = titleTextfield.text!
                updateObject?.dailyDate  = self.dateFormatter.date(from: (dateSelectButton.titleLabel?.text)!)!
                updateObject?.dailyCategory = categorySeg.selectedSegmentIndex
                updateObject?.dailyContents = contentsTextview.text
                updateObject?.dailyAlertOn     = alertOnOffSwitch.isOn
                // 알람 초기화
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(updateObject!.dailyNum)"])
                
                if alertOnOffSwitch.isOn {
                    updateObject?.dailyAlertDate = alertSettingButton.titleLabel!.text!
                                    
                    // Notification 3 - 로컬 알림에 보낼 메시지 생성
                    let content = UNMutableNotificationContent()
                    content.title       = updateObject!.dailyTitle
                    content.subtitle    = dateSelectButton.titleLabel!.text!
                    content.body        = updateObject!.dailyContents
                    
//                    print("일정 시간 : \(dateFormatter.string(from: updateObject!.dailyDate))")
    //                print("\(writeDaily.dailyDate - 3600)")
                    
                    var alertTime = Date()
                    
                    // 각 알람 시간 선택 했을 때 액션
                    switch self.alertSetArray.firstIndex(of: updateObject!.dailyAlertDate) {
                    case 0:
    //                    print("일정 정각")
                        alertTime = updateObject!.dailyDate
                    case 1:
    //                    print("5분 전")
                        alertTime = updateObject!.dailyDate - (5 * 60)
                    case 2:
    //                    print("10분 전")
                        alertTime = updateObject!.dailyDate - (10 * 60)
                    case 3:
    //                    print("15분 전")
                        alertTime = updateObject!.dailyDate - (15 * 60)
                    case 4:
    //                    print("30분 전")
                        alertTime = updateObject!.dailyDate - (30 * 60)
                    case 5:
    //                    print("1시간 전")
                        alertTime = updateObject!.dailyDate - (60 * 60)
                    case 6:
    //                    print("2시간 전")
                        alertTime = updateObject!.dailyDate - (120 * 60)
                    case 7:
    //                    print("1일 전")
                        alertTime = updateObject!.dailyDate - (24 * 60 * 60)
                    case 8:
    //                    print("2일 전")
                        alertTime = updateObject!.dailyDate - (48 * 60 * 60)
                    case 9:
    //                    print("1주 전")
                        alertTime = updateObject!.dailyDate - (7 * 24 * 60 * 60)
                    default:
                        print("default")
                    }
                    
//                    print("알람 시간 : \(dateFormatter.string(from: alertTime))")
                    
                    // Notification 4-2. 로컬 알림의 전송 시점 생성(캘린더)
                    //캘린더를 활용한 로컬 알림 ex. 3/1 오후 10시 정각
                    var cal = DateComponents()
                    cal.year    = alertTime.year
                    cal.month   = alertTime.month
                    cal.day     = alertTime.day
                    cal.hour    = alertTime.hour
                    cal.minute  = alertTime.minute
                    cal.second  = alertTime.second
                    
                    let calendarTrigger = UNCalendarNotificationTrigger(dateMatching: cal, repeats: false)
                    
                    // Notification 5. 로컬 알림을 요청할 준비 - (중요) identifier
                    // identifier : 로컬 알림의 고유 이름, 최대 64개까지 보낼 수 있음
                    let request = UNNotificationRequest(identifier: "\(updateObject!.dailyNum)", content: content, trigger: calendarTrigger)
                    
                    // Notification 6. 로컬 알림 최종 보내기
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                } else {
                    updateObject?.dailyAlertDate = ""
                }
            }

            if contentsImage.image != nil {
                savePhotosToDocumentDirectory(image: contentsImage.image!, fileName: "\(primaryKey).png")
            } else {
                //도큐먼트에 저장된 사진(ex. 18.jpg)을 Realm Data에 맞게 보여주기
                //1. 파일 시스템 접근
                let fileManager = FileManager.default
                
                //2. 도큐먼트 경로에 맞는 이미지 파일 이름 가져오기
                let imagePAth = (getDirectoryPath() as NSString).appendingPathComponent("\(primaryKey).png")
                
                //3. 이미지 파일이 존재할 경우, cell의 photoImageView에 해당 이미지 보여주기
                if fileManager.fileExists(atPath: imagePAth){
//                    self.contentsImage.image = UIImage(contentsOfFile: imagePAth)
//                    self.registerPicButton.setImage(nil, for: .normal)
                    try! fileManager.removeItem(atPath: imagePAth)
                }
            }
            self.navigationController?.popViewController(animated: true)
        }
        
    }
    
    // MARK: - Border 세팅
    func borderSetting() {
        let color = UIColor.lightGray.cgColor
        let width : CGFloat = 1
        
        let listView = [contentsTextview, contentsImage, titleTextfield, dateSelectButton, alertSettingButton]
        
        for item in listView {
            item?.layer.borderColor = color
            item?.layer.borderWidth = width
        }
    }
    
    // MARK: - Primary Key Function
    func createNewID() -> Int {
        // 기존 realm에 저장되어 있는 id(PK)를 숫자 높은 순으로 정렬, 그 값에 +1
        let realm = try! Realm()
        if let retNext = realm.objects(MyDailyTable.self).sorted(byKeyPath: "dailyNum", ascending : false).first?.dailyNum {
            return retNext + 1
        } else { return 2 }
    }
    
    // MARK: - 사진 관련 기능
    @IBAction func clickedPictureRegister(_ sender: UIButton) {
        let alert = UIAlertController(title: "일정 사진 등록", message: "", preferredStyle: .actionSheet)
        
        let registerAction = UIAlertAction(title: "사진 등록", style: .default, handler: { item in
            let picker = YPImagePicker()
            picker.didFinishPicking { [unowned picker] items, _ in
                if let photo = items.singlePhoto {
    //                print(photo.fromCamera) // Image source (camera or library)
    //                print(photo.image) // Final image selected by the user
                    
                    self.registerPicButton.setImage(nil, for: .normal)
                    self.contentsImage.image = photo.image
                    
    //                print(photo.originalImage) // original image selected by the user, unfiltered
    //                print(photo.modifiedImage) // Transformed image, can be nil
    //                print(photo.exifMeta) // Print exif meta data of original image. 정보 사진 장소
                }
                picker.dismiss(animated: true, completion: nil)
            }
            self.present(picker, animated: true, completion: nil)
        })
        
//        let viewAction = UIAlertAction(title: "사진 보기", style: .default, handler: { item in
//
//        })
        
        let deleteAction = UIAlertAction(title: "사진 삭제", style: .default, handler: { item in
            self.registerPicButton.setImage(UIImage(named: "plus"), for: .normal)
            self.contentsImage.image = nil
        })
        
        let cancelAction = UIAlertAction(title: "취소", style: .cancel, handler: nil)
        
        alert.addAction(registerAction)
//        alert.addAction(viewAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        self.present(alert, animated: true)
    }
}
