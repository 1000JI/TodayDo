//
//  AppJoinTableViewController.swift
//  GongNoRi
//
//  Created by 천지운 on 2019/10/25.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import iOSDropDown
import SwiftyJSON
import Alamofire

class AppJoinTableViewController: UITableViewController {
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var pw1Label: UILabel!
    @IBOutlet var pw2Label: UILabel!
    @IBOutlet var pwQuestionLabel: UILabel!
    @IBOutlet var pwAnswerLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var phoneLabel: UILabel!
    @IBOutlet var sexLabel: UILabel!
    @IBOutlet var dateLabel: UILabel!
    @IBOutlet var addrLabel: UILabel!
    @IBOutlet var positionLabel: UILabel!
    
    @IBOutlet var pictureRegButton: UIButton!
    @IBOutlet var overlapCheckButton: UIButton!
    @IBOutlet var submitJoinButton: UIButton!
    
    @IBOutlet var myBirthButton: UIButton!
    
    @IBOutlet var myPwQuestDropdown: DropDown!
    @IBOutlet var myAddr1Dropdown: DropDown!
    @IBOutlet var myAddr2Dropdown: DropDown!
    @IBOutlet var myPositionDropdown: DropDown!
    
    
    @IBOutlet var myPictureImageView: UIImageView!
    
    @IBOutlet var myIdTextField: UITextField!
    @IBOutlet var myPw1TextField: UITextField!
    @IBOutlet var myPw2TextField: UITextField!
    @IBOutlet var myPwAnswerTextField: UITextField!
    @IBOutlet var myNameTextField: UITextField!
    @IBOutlet var myPhone1TextField: UITextField!
    @IBOutlet var myPhone2TextField: UITextField!
    @IBOutlet var myPhone3TextField: UITextField!
    
    @IBOutlet var mySexSegment: UISegmentedControl!
    
    var bIDOverlapChecked   : Bool   = false
    var idOverlapCheckedID  : String = ""
    
    // MARK: - dateFormmater
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd hh:mm"
        formatter.locale = Locale(identifier:"ko_KR")
        return formatter
    }()
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        appJoinViewSetting()
    }
    
    // MARK: - 회원 가입 기능 구현
    @IBAction func clickedSubmit(_ sender: UIButton) {
        #if false
        if myIdTextField.text == "" {
            alertBasicFunction(string: "ID를 입력하세요.")
            return ;
        } else if bIDOverlapChecked == true {
            if myIdTextField.text != idOverlapCheckedID {
                alertBasicFunction(string: "ID 중복 체크하세요.")
                return ;
            }
        } else if bIDOverlapChecked == false {
            alertBasicFunction(string: "ID 중복 체크하세요.")
            return ;
        }
        
        if (myPw1TextField.text == "") || (myPw2TextField.text == "") {
            alertBasicFunction(string: "비밀번호를 입력하세요.")
            return ;
        } else if myPw1TextField.text != myPw2TextField.text {
            alertBasicFunction(string: "두 개의 비밀번호가 같지 않습니다.")
            return ;
        }
        
        if myPwAnswerTextField.text == "" {
            alertBasicFunction(string: "비밀번호 힌트에 대한 답변을 작성하세요.")
            return ;
        }
        
        if myNameTextField.text == ""{
            alertBasicFunction(string: "사용자의 이름을 작성하세요.")
            return ;
        }
        
        if (myPhone1TextField.text == "") || (myPhone2TextField.text == "") || (myPhone3TextField.text == "") {
            alertBasicFunction(string: "사용자의 휴대폰 번호를 확인하시고, 빠진 부분 없이 작성하세요.")
            return ;
        }
        
        if myBirthButton.titleLabel?.text == "생년월일 선택" {
            alertBasicFunction(string: "사용자의 생년월일을 선택하세요.")
            return ;
        }
        
        if (myAddr1Dropdown.text == "도시") || (myAddr2Dropdown.text == "지역") {
            alertBasicFunction(string: "사용자의 주소를 선택하세요.")
            return
        }
        #endif
        
        #if false
        
        let param : [String:Any] = ["id":""]
        let url = "http://13.209.40.207:8080/ballplay/InsertMember"
        
        Alamofire.request(url, method: .post, parameters: param).validate().responseJSON { response in
            switch response.result {
            case .success(let value):
                let json = JSON(value)
                print(json)
            case .failure(let error):
                print(error)
            }
        }
        #endif
    }
    
    
    // MARK: - ID 중복 체크 기능 구현
    @IBAction func clickedIDOverlapCheck(_ sender: UIButton) {
        let checkID = myIdTextField.text
        
        if checkID == "" {
            // Alert
            // 1. 알람창 생성(alert, actionsheet)
            let alert = UIAlertController(title: "ID 입력", message: "ID 중복 확인을 위해 ID를 입력해주세요", preferredStyle: .alert)
            
            // 2. 버튼 생성
            //  style : .default(기본), .cancel(별도 구성), destructive(빨간 글씨)
            let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            // 3. 알림창에 버튼 추가
            alert.addAction(okButton)
            
            // 4. 알림창 표출
            self.present(alert, animated: true, completion: nil)
        } else {
            let param : [String:Any] = ["id":checkID!]
            let url = "http://13.209.40.207:8080/ballplay/IdCheck"
            
            Alamofire.request(url, method: .post, parameters: param).validate().responseJSON { response in
                switch response.result {
                case .success(let value):
                    let json = JSON(value)
                    
                    var alertTitle   : String = ""
                    var alertMessage : String = ""
                    
                    if json["result"] == "success" {
                        self.bIDOverlapChecked = true
                        self.idOverlapCheckedID = checkID!
                        
                        alertTitle = "ID 사용 가능"
                        alertMessage = "ID가 중복되지 않습니다."
                    } else {
                        self.bIDOverlapChecked = false
                        alertTitle = "ID 중복"
                        alertMessage = "다른 ID를 입력해주세요."
                    }
                    
                    // Alert
                    // 1. 알람창 생성(alert, actionsheet)
                    let alert = UIAlertController(title: alertTitle, message: alertMessage, preferredStyle: .alert)
                    
                    // 2. 버튼 생성
                    //  style : .default(기본), .cancel(별도 구성), destructive(빨간 글씨)
                    let okButton = UIAlertAction(title: "OK", style: .default, handler: nil)
                    
                    // 3. 알림창에 버튼 추가
                    alert.addAction(okButton)
                    
                    // 4. 알림창 표출
                    self.present(alert, animated: true, completion: nil)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
    
    // MARK: - 사진 등록 부분 카메라 기능 구현
    
    // MARK: - 회원가입 폼 디자인 세팅
    func appJoinViewSetting() {
        self.title = "회원가입"
        // image design
        self.myPictureImageView.layer.cornerRadius = self.myPictureImageView.frame.width * 0.5
//        self.myPictureImageView.backgroundColor = .lightGray
        self.myPictureImageView.layer.borderColor = UIColor.lightGray.cgColor
        self.myPictureImageView.layer.borderWidth = 1

        // label design
        let labelArray = [self.idLabel, self.pw1Label, self.pw2Label, self.pwQuestionLabel, self.pwAnswerLabel, self.nameLabel, self.phoneLabel, self.sexLabel, self.dateLabel, self.addrLabel, self.positionLabel]
        
        for row in 0..<labelArray.count {
            labelArray[row]?.font = fontCoreDreamLight(fontSize: 17)
        }
        
        // textfield design
        let textFieldArray = [self.myIdTextField, self.myPw1TextField, self.myPw2TextField, self.myPwAnswerTextField, self.myNameTextField, self.myPhone1TextField, self.myPhone2TextField, self.myPhone3TextField]
        
        for row in 0..<textFieldArray.count {
            textFieldArray[row]?.font = fontCoreDreamLight(fontSize: 15)
            textFieldArray[row]?.layer.borderWidth = 1
            textFieldArray[row]?.layer.borderColor = UIColor.lightGray.cgColor
        }
        self.myPw1TextField.isSecureTextEntry = true
        self.myPw2TextField.isSecureTextEntry = true
        
        self.myPhone1TextField.keyboardType = .numberPad
        self.myPhone2TextField.keyboardType = .numberPad
        self.myPhone3TextField.keyboardType = .numberPad
        
        // dropdown design
        let dropdownArray = [myPwQuestDropdown, myAddr1Dropdown, myAddr2Dropdown, myPositionDropdown]
        
        for row in 0..<dropdownArray.count {
            dropdownArray[row]?.font = fontCoreDreamLight(fontSize: 13)
            dropdownArray[row]?.borderColor = .lightGray
            dropdownArray[row]?.borderWidth = 1
        }
        
        self.myPwQuestDropdown.optionArray = passwordQuestionList
        self.myPwQuestDropdown.font = fontCoreDreamLight(fontSize: 10)
        self.myPwQuestDropdown.text = passwordQuestionList[0]
        
        self.myPositionDropdown.optionArray = positionList
        self.myPositionDropdown.text = positionList[0]
        
        let fileName = "korea-administrative-district"
        if let path = Bundle.main.path(forResource: fileName, ofType: "json") {
                do {
                    let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                    let json = try JSON(data : data)
                   // print("JSON : \(json)")
                    let jsonData = json["data"]
                    print(jsonData)

                    for row in 0..<jsonData.count {
                        let rowData = jsonData[row].dictionaryValue.keys.description.components(separatedBy: "\"")
                        address1List.append(rowData[1])
                    }

                    self.myAddr1Dropdown.optionArray = address1List
                    self.myAddr1Dropdown.text = "도시"
                    self.myAddr2Dropdown.text = "지역"
                    self.myAddr2Dropdown.isEnabled = false

                    self.myAddr1Dropdown.didSelect(completion: { (selected, index, id) in
                        self.myAddr2Dropdown.isEnabled = true
                        self.myAddr2Dropdown.text = "지역"
                        address2List.removeAll()
                        let addr2List = jsonData[index][selected]

                        for row in 0..<addr2List.count {
                            address2List.append(addr2List[row].stringValue)
                        }

                        self.myAddr2Dropdown.optionArray = address2List
                    })
                      
                } catch {
                    // handle error
                }
            }
        
//        let FullPath = "korea-administrative-district.json"
//        let FullPath = "/Users/jiwooni/Desktop/GongNoRi/GongNoRi/korea-administrative-district.json"
//
//        if let contents = try? String(contentsOfFile: FullPath).data(using: .utf8) {
//            let json = JSON(contents)
//
//        }
        
        // button design
        self.pictureRegButton.titleLabel?.font = fontCoreDreamHeavy(fontSize: 17)
        self.pictureRegButton.setTitle("사진등록", for: .normal)
        self.pictureRegButton.backgroundColor = .clear
        self.pictureRegButton.setTitleColor(.lightGray, for: .normal)
        
        let buttonArray = [self.myBirthButton]
        
        for row in 0..<buttonArray.count {
            buttonArray[row]?.titleLabel?.font = fontCoreDreamLight(fontSize: 17)
            buttonArray[row]?.layer.borderWidth = 1
            buttonArray[row]?.layer.borderColor = UIColor.lightGray.cgColor
        }
        
        
        self.overlapCheckButton.titleLabel?.font = fontCoreDreamHeavy(fontSize: 15)
        self.overlapCheckButton.setTitle("중복확인", for: .normal)
        self.overlapCheckButton.backgroundColor = .lightGray
        
        self.submitJoinButton.titleLabel?.font = fontCoreDreamHeavy(fontSize: 20)
        self.submitJoinButton.setTitle("회원가입", for: .normal)
        self.submitJoinButton.backgroundColor = .lightGray
        
    }
    
    // MARK: - 생년월일 버튼 기능 구현
    @IBAction func clickedBirthPick(_ sender: UIButton) {
        let date = Date()
        
//        let alert = UIAlertController(title: "날짜 선택", message: nil, preferredStyle: .actionSheet)
        
        let alert = UIAlertController(style: .actionSheet, title: "날짜 선택")
        alert.addDatePicker(mode: .dateAndTime, date: date, minimumDate: nil, maximumDate: nil) { date in
            
            self.myBirthButton.setTitle("\(self.dateFormatter.string(from: date))", for: .normal)
        }
        alert.addAction(title: "확인", style: .cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func clickedBackButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func alertBasicFunction(string:String) {
        // Alert
        // 1. 알람창 생성(alert, actionsheet)
        let alert = UIAlertController(title: "회원가입 실패", message: string, preferredStyle: .alert)
        
        
        // 2. 버튼 생성
        //  style : .default(기본), .cancel(별도 구성), destructive(빨간 글씨)
        let okButton = UIAlertAction(title: "확인", style: .destructive, handler: nil)
        
        // 3. 알림창에 버튼 추가
        alert.addAction(okButton)
        
        // 4. 알림창 표출
        self.present(alert, animated: true, completion: nil)
    }
    

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return super.tableView(tableView, numberOfRowsInSection: section)
    }
}
