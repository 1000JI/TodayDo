//
//  CategorySettingViewController.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/28.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift

class CategorySettingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate {
    
    @IBOutlet var categoryListTable: UITableView!
    @IBOutlet var colorCollectionView: UICollectionView!
    @IBOutlet var collectionViewTitleLabel: UILabel!

    // Realm에 접근하겠다는 트리거 생성, Realm에 변화가 있다면 무조건 거쳐감!
    let realm = try! Realm()

    // Realm에서 데이터를 가져와 담을 공간 생성
    var realmList           : Results<MyDailyTable>!    // 일정 저장 테이블
    var realmCategoryList   : Results<MyCategoryTable>! // 카테고리 저장 테이블
    
    var clickedColorIndex   : Int = 0
    var clickedButton       : UIButton?
    
    var selectCategory      : Results<MyCategoryTable>!
    
    override func viewWillAppear(_ animated: Bool) {
        colorCollectionView.isHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        categoryListTable.dataSource = self
        categoryListTable.delegate = self
        categoryListTable.allowsSelection = false
        
        colorCollectionView.dataSource = self
        colorCollectionView.delegate = self
        
        categoryNavigationBarSetting()
        databaseRealmSetting()
        colorCollectionViewSetting()
        
        collectionViewTitleLabel.text = "카테고리 색상표(색상은 바로 저장됩니다)"
        collectionViewTitleLabel.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 18)
        collectionViewTitleLabel.textAlignment = .center
        collectionViewTitleLabel.layer.borderColor = UIColor.lightGray.cgColor
        collectionViewTitleLabel.layer.borderWidth = 1
        collectionViewTitleLabel.backgroundColor = .white
    }

    // MARK: - navigation bar setting
    func categoryNavigationBarSetting() {
//        self.navigationController?.navigationBar.barTintColor = UIColor().customPinkBar
        self.navigationController?.navigationBar.barTintColor = .white
        self.navigationController?.navigationBar.isTranslucent = false
        
        self.title = "카테고리 설정"
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "return"), style: .plain, target: self, action: #selector(clickedReturnLeftBarItem))
        self.navigationItem.leftBarButtonItem?.tintColor = .black
        
        let saveBarButton = UIBarButtonItem(image: UIImage(named: "save"), style: .plain, target: self, action: #selector(clickedSaveRightBarItem))
        let addBarButton = UIBarButtonItem(image: UIImage(named: "plus"), style: .plain, target: self, action: #selector(clickedAddRightBarItem))
        saveBarButton.tintColor = .black
        addBarButton.tintColor = .black
        
        self.navigationItem.rightBarButtonItems = [saveBarButton, addBarButton]
    }
    
    // clickedReturnLeftBarItem
    @objc func clickedReturnLeftBarItem() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // clickedSaveRightBarItem
    @objc func clickedSaveRightBarItem() {
        categoryTableSaveFunction()
        let alert = UIAlertController(title: "저장 완료", message: "카테고리가 정상적으로 저장되었습니다.", preferredStyle: .alert)

        let okButton = UIAlertAction(title: "확인", style: .default, handler: { item in
            self.dismiss(animated: true, completion: nil)
        })

        alert.addAction(okButton)
        self.present(alert, animated: true)
    }
    
    // clickedAddRightBarItem
    @objc func clickedAddRightBarItem() {
        collectionViewClear()
        categoryTableSaveFunction() // 저장
        
        if realmCategoryList.count >= 7 {
            let alert = UIAlertController(title: "알림메세지", message: "카테고리는 최대 7개까지 추가가 가능합니다.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
            self.present(alert, animated: true)
        } else {
            let addCategory = MyCategoryTable()
            addCategory.categoryNum = categoryCreateNewID()
            addCategory.categoryIndex = categoryCreateNewIndex()
            addCategory.categoryTitle = "기본"
            addCategory.categoryContext = ""
            addCategory.categoryColor = Int.random(in: 0..<rgbPalette.count)
            
            try! realm.write {
                realm.add(addCategory)
            }
            categoryListTable.reloadData()
        }
    }
    
    func categoryTableSaveFunction() {
        let saveCells = categoryListTable.visibleCells as! [CategoryTableViewCell]
        
        for row in 0..<saveCells.count {
            if saveCells[row].titleTextField.text == "" {
                let alert = UIAlertController(title: "알림메세지", message: "카테고리 중 제목을 안쓴 카테고리가 있습니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: { item in
                    return ;
                }))
                self.present(alert, animated: true)
            }
        }
        
        for row in 0..<saveCells.count {
            let saveCategoryTable = MyCategoryTable()
            saveCategoryTable.categoryTitle = saveCells[row].titleTextField.text!
            saveCategoryTable.categoryContext = saveCells[row].subtitleTextField.text!
            saveCategoryTable.categoryNum = Int("\(saveCells[row].colorButton.titleLabel!.text!)")!
            
            let categoryColor = realm.objects(MyCategoryTable.self).filter("categoryNum == \(saveCells[row].colorButton!.titleLabel!.text!)")
            saveCategoryTable.categoryColor = categoryColor[0].categoryColor
            saveCategoryTable.categoryIndex = Int(saveCells[row].indexLabel.text!)! - 1
            
            try! realm.write {
                realm.add(saveCategoryTable, update: .modified)
            }
        }
    }
    
    // MARK: createNewID()
    func categoryCreateNewID() -> Int {
        // 기존 realm에 저장되어 있는 id(PK)를 숫자 높은 순으로 정렬, 그 값에 +1
        if let retNext = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending : false).first?.categoryNum {
            return retNext + 1
        } else { return 2 }
    }
    
    func categoryCreateNewIndex() -> Int {
        // 기존 realm에 저장되어 있는 id(PK)를 숫자 높은 순으로 정렬, 그 값에 +1
        if let retNext = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryIndex", ascending : false).first?.categoryIndex {
            return retNext + 1
        } else { return 2 }
    }
    
    // MARK: - categoryListTable Method
    func databaseRealmSetting(){
        realmCategoryList = realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
    }
    
    // MARK: numberOfRowsInSection
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return realmCategoryList.count
    }
    
    // MARK: cellForRowAt
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CategoryTableViewCell", for: indexPath) as! CategoryTableViewCell
        
        cell.layer.borderColor = UIColor().customGray.cgColor//UIColor.lightGray.cgColor
        cell.layer.borderWidth = 0.5
        
        cell.indexLabel.textAlignment = .center
        cell.indexLabel.font = fontCoreDreamLight(fontSize: 18)
        cell.indexLabel.text = "\(indexPath.row + 1)"
        
        cell.titleTextField.delegate = self
        cell.titleTextField.layer.borderWidth = 0.5
        cell.titleTextField.layer.borderColor = UIColor.lightGray.cgColor
        cell.titleTextField.font = fontCoreDreamLight(fontSize: 18)//fontCoreDreamHeavy(fontSize: 18)
        cell.titleTextField.text = realmCategoryList[indexPath.row].categoryTitle
        cell.titleTextField.textAlignment = .center
        cell.titleTextField.addTarget(self, action: #selector(clickedTextField), for: .editingDidBegin)
        cell.titleTextField.addTarget(self, action: #selector(writeLimitTextfield), for: .allEditingEvents)
        
        cell.subtitleTextField.delegate = self
        cell.subtitleTextField.layer.borderWidth = 0.5
        cell.subtitleTextField.layer.borderColor = UIColor.lightGray.cgColor
        cell.subtitleTextField.font = fontCoreDreamLight(fontSize: 18)
        cell.subtitleTextField.text = realmCategoryList[indexPath.row].categoryContext
        cell.subtitleTextField.textAlignment = .left
        cell.subtitleTextField.placeholder = "세부 내용(선택))"
        cell.subtitleTextField.addTarget(self, action: #selector(clickedTextField), for: .editingDidBegin)
        
        cell.colorButton.backgroundColor = rgbPalette[realmCategoryList[indexPath.row].categoryColor]
        cell.colorButton.setTitle("\(realmCategoryList[indexPath.row].categoryNum)", for: .normal)
        cell.colorButton.setTitleColor(.clear, for: .normal)
        cell.colorButton.addTarget(self, action: #selector(clickedCategoryColorChange), for: .touchUpInside)
        cell.colorButton.layer.borderWidth = 0
        cell.colorButton.layer.borderColor = UIColor.clear.cgColor
        return cell
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()  //if desired
        return true
    }
    
    @objc func writeLimitTextfield(sender: UITextField) {
        if sender.text!.count > 2 {
            sender.text?.removeLast()
        }
    }
    
    @objc func clickedTextField() {
        collectionViewClear()
    }
    
    // MARK: clickedCategoryColorChange
    @objc func clickedCategoryColorChange(sender: UIButton) {
        view.endEditing(true)
        colorCollectionView.isHidden = false
        let selectNum = Int(sender.titleLabel!.text!)!
        if sender != clickedButton {
            if clickedButton != nil {
                clickedButton!.layer.borderWidth = 0
                clickedButton!.layer.borderColor = UIColor.clear.cgColor
            }
            clickedButton = sender
        }
        sender.layer.borderWidth = 5
        sender.layer.borderColor = UIColor.black.cgColor
        
        selectCategory = realm.objects(MyCategoryTable.self).filter("categoryNum == \(selectNum)")
        clickedColorIndex = selectCategory[0].categoryColor
        colorCollectionView.reloadData()
    }
    
    // MARK: heightForRowAt
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // MARK: titleForHeaderInSection
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "카테고리(2글자) 분류 7개까지 추가 가능"
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteButton = UIContextualAction(style: .destructive, title: "삭제") { (action : UIContextualAction, view : UIView, success : (Bool) -> Void) in
            self.categoryTableSaveFunction()
            
            if self.realmCategoryList.count <= 1 {
                let alert = UIAlertController(title: "알림메세지", message: "카테고리는 최소 1개는 있어야 합니다.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "확인", style: .default, handler: nil))
                self.present(alert, animated: true)
            } else {
                let cell = tableView.cellForRow(at: indexPath) as! CategoryTableViewCell
                let deleteIndex = Int("\(cell.indexLabel.text!)")! - 1
                let deleteObject = self.realm.objects(MyCategoryTable.self).filter("categoryIndex == \(deleteIndex)")

                try! self.realm.write {
                    self.realm.delete(deleteObject[0])
                }

                let reloadObjects = self.realm.objects(MyCategoryTable.self).sorted(byKeyPath: "categoryNum", ascending: true)
                for row in 0..<reloadObjects.count {
                    let tempChangeCategory = MyCategoryTable()
                    tempChangeCategory.categoryNum = reloadObjects[row].categoryNum
                    tempChangeCategory.categoryTitle = reloadObjects[row].categoryTitle
                    tempChangeCategory.categoryContext = reloadObjects[row].categoryContext
                    tempChangeCategory.categoryColor = reloadObjects[row].categoryColor
                    tempChangeCategory.categoryIndex = row
                    try! self.realm.write {
                        self.realm.add(tempChangeCategory, update: .modified)
                    }
                }
                
                let updateDailyList = self.realm.objects(MyDailyTable.self).sorted(byKeyPath: "dailyNum", ascending: true)
                for row in 0..<updateDailyList.count {
                    let editTempTable = MyDailyTable()
                    editTempTable.dailyNum = updateDailyList[row].dailyNum
                    editTempTable.dailyDate = updateDailyList[row].dailyDate
                    editTempTable.dailyTitle = updateDailyList[row].dailyTitle
                    editTempTable.dailyContents = updateDailyList[row].dailyContents
                    editTempTable.dailyIsHoliday = updateDailyList[row].dailyIsHoliday
//                        editTempTable.dailyImage = updateDailyList[row].dailyImage

                    if updateDailyList[row].dailyCategory == deleteIndex {
                        print("\(updateDailyList[row].dailyCategory) == \(deleteIndex)")
                        editTempTable.dailyCategory = 0
                    } else if updateDailyList[row].dailyCategory > deleteIndex {
                        print("\(updateDailyList[row].dailyCategory) != \(deleteIndex)" )
                        editTempTable.dailyCategory = updateDailyList[row].dailyCategory - 1
                    } else {
                        editTempTable.dailyCategory = updateDailyList[row].dailyCategory
                    }

                    try! self.realm.write {
                        self.realm.add(editTempTable, update: .modified)
                    }
                }
                self.categoryListTable.reloadData()
            }
        }
        return UISwipeActionsConfiguration(actions: [deleteButton])
    }
    
    // MARK: - colorCollection Method
    // MARK: colorCollection View Setting
    func colorCollectionViewSetting() {
        let screenSize = UIScreen.main.bounds
        let screenWidth = screenSize.width
    
        // Do any additional setup after loading the view, typically from a nib
        let layout: UICollectionViewFlowLayout = UICollectionViewFlowLayout()
//        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        layout.itemSize = CGSize(width: screenWidth / 7, height: screenWidth / 7)
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        
        colorCollectionView.collectionViewLayout = layout
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
        
        let tempCategoryTable = MyCategoryTable()
        tempCategoryTable.categoryNum = selectCategory[0].categoryNum
        tempCategoryTable.categoryTitle = selectCategory[0].categoryTitle
        tempCategoryTable.categoryContext = selectCategory[0].categoryContext
        tempCategoryTable.categoryColor = clickedColorIndex
        
        try! realm.write {
            realm.add(tempCategoryTable, update: .modified)
        }
        
        clickedButton?.backgroundColor = rgbPalette[clickedColorIndex]
        colorCollectionView.reloadData()
    }
    
    func collectionViewClear() {
        colorCollectionView.isHidden = true
        if clickedButton != nil {
            clickedButton!.layer.borderWidth = 0
            clickedButton!.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
