//
//  CalendarColorViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2020/01/09.
//  Copyright © 2020 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift

class CalendarColorViewController: UIViewController {

    @IBOutlet var titleLabel: UILabel!
    
    @IBOutlet var viewHolidayView: UIView!
    @IBOutlet var viewSatView: UIView!
    @IBOutlet var viewDefaultView: UIView!
    @IBOutlet var viewSub1View: UIView!
    @IBOutlet var viewSub2View: UIView!
    
    @IBOutlet var backgroundSub1View: UIView!
    @IBOutlet var backgroundSub2View: UIView!
    
    @IBOutlet var titleHolidayLabel: UILabel!
    @IBOutlet var titleSatLabel: UILabel!
    @IBOutlet var titleDefaultLabel: UILabel!
    @IBOutlet var titleSubTitle1Label: UILabel!
    @IBOutlet var titleSubTitle2Label: UILabel!
    
    @IBOutlet var titleSub1Label: UILabel!
    @IBOutlet var titleSub2Label: UILabel!
    
    @IBOutlet var dateHolidayLabel: UILabel!
    @IBOutlet var dateSatLabel: UILabel!
    @IBOutlet var dateDefaultLabel: UILabel!
    
    @IBOutlet var dotHolidayView: UIView!
    
    @IBOutlet var setButton1: UIButton!
    @IBOutlet var setButton2: UIButton!
    @IBOutlet var setButton3: UIButton!
    @IBOutlet var setButton4: UIButton!
    @IBOutlet var setButton5: UIButton!
    
    @IBOutlet var titleColorLabel: UILabel!
    @IBOutlet var colorListCollectionView: UICollectionView!
    
    @IBOutlet var initButton: UIButton!
    
    var clickedColorIndex   : Int = 0
    var indexHoliday        : Int = 0
    var indexSat            : Int = 0
    var indexDefault        : Int = 0
    var indexSub1           : Int = 0
    var indexSub2           : Int = 0
    
    var presentButton: UIButton?
    
    let realm = try! Realm()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        colorListCollectionView.delegate = self
        colorListCollectionView.dataSource = self
        
        viewInit()
        getUserSetting()
        
    }
    
    // MARK: - 사용자 데이터 가져오기
    func getUserSetting() {
        
        let dbColorTable = realm.objects(MySettingTable.self).first
        indexHoliday    = dbColorTable!.indexHoliday
        indexSat        = dbColorTable!.indexSaturday
        indexDefault    = dbColorTable!.indexDefault
        indexSub1       = dbColorTable!.indexTodayColor
        indexSub2       = dbColorTable!.indexSelectColor
        
        dateViewSetting(dateHolidayLabel, 20, "1", rgbPalette[indexHoliday])
        dateViewSetting(dateSatLabel, 20, "2", rgbPalette[indexSat])
        dateViewSetting(dateDefaultLabel, 20, "3", rgbPalette[indexDefault])
        dateViewSetting(titleSub1Label, 20, "4", .white)
        dateViewSetting(titleSub2Label, 20, "5", .white)
        
        dotViewSetting(dotHolidayView, rgbPalette[indexHoliday])
        dotViewSetting(backgroundSub1View, rgbPalette[indexSub1])
        dotViewSetting(backgroundSub2View, rgbPalette[indexSub2])
        
    }
    
    // MARK: - 전체적인 뷰 구성
    func viewInit() {
        
        self.title = "설정 화면"
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(clickedReturnButton))
        self.navigationItem.leftBarButtonItem?.tintColor = .black
        
        let saveBarButton = UIBarButtonItem(image: UIImage(named: "save"), style: .plain, target: self, action: #selector(clickedSaveButton))
        saveBarButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItem = saveBarButton
        
        titleLabel.text = "캘린더 색상 지정"
        titleLabel.font = fontCoreDreamLight(fontSize: 24)
        titleLabel.textAlignment = .center
        
        let viewList = [viewHolidayView, viewSatView, viewDefaultView, viewSub1View, viewSub2View]
        
        for viewItem in viewList {
            viewItem?.layer.borderColor = UIColor.darkGray.cgColor
            viewItem?.layer.borderWidth = 0.5
        }
        
        titleViewSetting(titleHolidayLabel, 18, "공휴일")
        titleViewSetting(titleSatLabel, 18, "토요일")
        titleViewSetting(titleDefaultLabel, 18, "평일")
        titleViewSetting(titleSubTitle1Label, 18, "오늘")
        titleViewSetting(titleSubTitle2Label, 18, "선택")
        
        dateViewSetting(dateHolidayLabel, 20, "1", .red)
        dateViewSetting(dateSatLabel, 20, "2", .blue)
        dateViewSetting(dateDefaultLabel, 20, "3", .black)
        dateViewSetting(titleSub1Label, 20, "4", .white)
        dateViewSetting(titleSub2Label, 20, "5", .white)
        
        dotViewSetting(dotHolidayView, .red)
        dotViewSetting(backgroundSub1View, .red)
        dotViewSetting(backgroundSub2View, .purple)
        
        let buttonList = [setButton1, setButton2, setButton3, setButton4, setButton5]
        
        for buttonItem in buttonList {
            buttonItem?.layer.borderColor = UIColor.darkGray.cgColor
            buttonItem?.layer.borderWidth = 0.5
            buttonItem?.titleLabel?.font = fontCoreDreamLight(fontSize: 16)
            buttonItem?.setTitleColor(.black, for: .normal)
            buttonItem?.setTitle("변경", for: .normal)
            buttonItem?.tintColor = .clear
            buttonItem?.addTarget(self, action: #selector(clickedSetButton), for: .touchUpInside)
        }
        
        setButton1.isSelected = true
        setButton1.backgroundColor = .lightGray
        presentButton = setButton1
        
        titleColorLabel.font = fontCoreDreamLight(fontSize: 20)
        titleColorLabel.text = "카테고리 색상표"
        titleColorLabel.textAlignment = .center
        titleColorLabel.layer.borderColor = UIColor.darkGray.cgColor
        titleColorLabel.layer.borderWidth = 0.5
        
        initButton.layer.borderColor = UIColor.darkGray.cgColor
        initButton.layer.borderWidth = 0.5
        initButton.titleLabel?.font = fontCoreDreamLight(fontSize: 20)
        initButton.setTitleColor(.black, for: .normal)
        initButton.setTitle("초기화", for: .normal)
        initButton.tintColor = .clear
        initButton.addTarget(self, action: #selector(clickedColorInit), for: .touchUpInside)
        
        colorCollectionViewSetting()
    }
    
    // MARK: - 초기화 버튼 이벤트
    @objc func clickedColorInit() {
        
        indexHoliday    = SaveBasicColor.HolidayColor
        indexSat        = SaveBasicColor.SaturdayColor
        indexDefault    = SaveBasicColor.DefaultColor
        indexSub1       = SaveBasicColor.TodayColor
        indexSub2       = SaveBasicColor.SelectColor
        
        dateViewSetting(dateHolidayLabel, 20, "1", rgbPalette[indexHoliday])
        dateViewSetting(dateSatLabel, 20, "2", rgbPalette[indexSat])
        dateViewSetting(dateDefaultLabel, 20, "3", rgbPalette[indexDefault])
        dateViewSetting(titleSub1Label, 20, "4", .white)
        dateViewSetting(titleSub2Label, 20, "5", .white)
        
        dotViewSetting(dotHolidayView, rgbPalette[indexHoliday])
        dotViewSetting(backgroundSub1View, rgbPalette[indexSub1])
        dotViewSetting(backgroundSub2View, rgbPalette[indexSub2])
        
        colorListCollectionView.reloadData()
        
    }
    
    // MARK: - 뒤로가기 버튼 이벤트
    @objc func clickedReturnButton() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - 저장 버튼 이벤트
    @objc func clickedSaveButton() {
        
        let dbColorTable = realm.objects(MySettingTable.self).first
        
        try! realm.write {
            dbColorTable?.indexHoliday      = indexHoliday
            dbColorTable?.indexSaturday     = indexSat
            dbColorTable?.indexDefault      = indexDefault
            dbColorTable?.indexTodayColor   = indexSub1
            dbColorTable?.indexSelectColor  = indexSub2
        }
        
        let confirmAlert = UIAlertController(title: "저장 완료", message: "해당 색상이 저장되었습니다.", preferredStyle: .alert)
        
        confirmAlert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
            self.dismiss(animated: true, completion: nil)
        }))
        
        self.present(confirmAlert, animated: true)
        
    }
    
    // MARK: - 버튼 이벤트
    @objc func clickedSetButton(_ sender: UIButton) {
        
        if let button = presentButton {
            button.isSelected = !button.isSelected
            button.backgroundColor = .white
        }
        
        presentButton = sender
        sender.isSelected = !sender.isSelected
        
        if sender.isSelected {
            sender.backgroundColor = .lightGray
        }
        
        let buttonList = [setButton1, setButton2, setButton3, setButton4, setButton5]
        
        switch buttonList.firstIndex(of: presentButton) {
        case 0:
            clickedColorIndex = indexHoliday
        case 1:
            clickedColorIndex = indexSat
        case 2:
            clickedColorIndex = indexDefault
        case 3:
            clickedColorIndex = indexSub1
        case 4:
            clickedColorIndex = indexSub2
        default:
            print("error")
        }
        colorListCollectionView.reloadData()
        
    }
    
    // MARK: - 폰트, 색상 지정
    // MARK: 타이틀 폰트 지정
    func titleViewSetting(_ label: UILabel, _ fontSize: Int, _ text: String) {
        label.font = fontCoreDreamLight(fontSize: fontSize)
        label.textAlignment = .center
        label.text = text
    }
    
    // MARK: 날짜 폰트, 색상 지정
    func dateViewSetting(_ label: UILabel, _ fontSize: Int, _ text: String, _ setColor: UIColor) {
        label.font = fontCoreDreamLight(fontSize: fontSize)
        label.textAlignment = .center
        label.textColor = setColor
        label.text = text
    }
    
    // MARK: Dot 색상 지정
    func dotViewSetting(_ dotView: UIView, _ setColor: UIColor) {
        dotView.backgroundColor = setColor
        dotView.layer.cornerRadius = dotView.frame.size.width / 2
    }
}

extension CalendarColorViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    // MARK: - colorCollection Method
    // MARK: colorCollection View Setting
    func colorCollectionViewSetting() {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
    
        // Do any additional setup after loading the view, typically from a nib
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: screenWidth / 7, height: screenWidth / 7)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        colorListCollectionView.collectionViewLayout = layout
    }
    
    // MARK: numberOfItemsInSection
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return rgbPalette.count
    }
    
    // MARK: cellForItemAt
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCollectionViewCell", for: indexPath) as! ColorCollectionViewCell
        cell.colorLabel.backgroundColor = rgbPalette[indexPath.row]
        
        if clickedColorIndex == (indexPath.row) {
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 5
        } else {
            cell.layer.borderColor = UIColor.white.cgColor
            cell.layer.borderWidth = 0.5
        }
        
        return cell
    }
    
    // MARK: didSelectItemAt
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        clickedColorIndex = indexPath.row

        let buttonList = [setButton1, setButton2, setButton3, setButton4, setButton5]
        
        switch buttonList.firstIndex(of: presentButton) {
        case 0:
            dateViewSetting(dateHolidayLabel, 20, "1", rgbPalette[clickedColorIndex])
            dotViewSetting(dotHolidayView, rgbPalette[clickedColorIndex])
            indexHoliday = clickedColorIndex
        case 1:
            dateViewSetting(dateSatLabel, 20, "2", rgbPalette[clickedColorIndex])
            indexSat = clickedColorIndex
        case 2:
            dateViewSetting(dateDefaultLabel, 20, "3", rgbPalette[clickedColorIndex])
            indexDefault = clickedColorIndex
        case 3:
            dotViewSetting(backgroundSub1View, rgbPalette[clickedColorIndex])
            indexSub1 = clickedColorIndex
        case 4:
            dotViewSetting(backgroundSub2View, rgbPalette[clickedColorIndex])
            indexSub2 = clickedColorIndex
        default:
            print("error")
        }
        
        colorListCollectionView.reloadData()
    }
    
}
