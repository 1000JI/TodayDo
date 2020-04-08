//
//  LoginViewController.swift
//  GongNoRi
//
//  Created by 천지운 on 2019/10/24.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController {
    @IBOutlet var loginTopView: UIView!
    
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var pwLabel: UILabel!
    
    @IBOutlet var idTextField: UITextField!
    @IBOutlet var pwTextField: UITextField!
    
    @IBOutlet var loginButton: UIButton!
    @IBOutlet var joinButton: UIButton!
    @IBOutlet var idFindButton: UIButton!
    @IBOutlet var pwFindButton: UIButton!
    
    @IBOutlet var kakaoLogin: UIButton!
    @IBOutlet var naverLogin: UIButton!
    
    @IBOutlet var autoLoginButton: UIButton!
    @IBOutlet var autoLoginLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loginViewSetting()
    }
    
    // MARK: - 메인 화면 디자인 구성
    func loginViewSetting() {
        let red     = CGFloat(185 / 255.0)
        let green   = CGFloat(219 / 255.0)
        let blue    = CGFloat(156 / 255.0)
        loginTopView.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1.0)
        
        
        titleLabel.font = fontCoreDreamHeavy(fontSize: 40)
        titleLabel.text = "공노리"
        titleLabel.textAlignment = .center
        
        idLabel.font = fontCoreDreamLight(fontSize: 20)
        idLabel.textAlignment = .right
        idLabel.text = "아이디"
        
        idTextField.font = fontCoreDreamLight(fontSize: 17)
        
        pwTextField.font = fontCoreDreamLight(fontSize: 17)
        pwTextField.isSecureTextEntry = true
        
        pwLabel.font = fontCoreDreamLight(fontSize: 20)
        pwLabel.textAlignment = .right
        pwLabel.text = "비밀번호"
        
        loginButton.titleLabel?.font = fontCoreDreamLight(fontSize: 20)
        loginButton.setTitle("로그인", for: .normal)
        loginButton.titleLabel?.textAlignment = .right
        loginButton.setTitleColor(.black, for: .normal)
        
        joinButton.titleLabel?.font = fontCoreDreamLight(fontSize: 20)
        joinButton.setTitle("회원가입", for: .normal)
        joinButton.titleLabel?.textAlignment = .left
        joinButton.setTitleColor(.black, for: .normal)
        
        idFindButton.titleLabel?.font = fontCoreDreamLight(fontSize: 15)
        idFindButton.setTitleColor(.darkGray, for: .normal)
        idFindButton.titleLabel?.textAlignment = .right
        idFindButton.setTitle("ID 찾기", for: .normal)
        
        pwFindButton.titleLabel?.font = fontCoreDreamLight(fontSize: 15)
        pwFindButton.setTitleColor(.darkGray, for: .normal)
        pwFindButton.titleLabel?.textAlignment = .left
        pwFindButton.setTitle("PW 찾기", for: .normal)
        
        kakaoLogin.titleLabel?.font = fontCoreDreamHeavy(fontSize: 25)
        kakaoLogin.setTitle("KAKAO 로그인", for: .normal)
        kakaoLogin.setTitleColor(.black, for: .normal)
        kakaoLogin.backgroundColor = .systemYellow
        
        naverLogin.titleLabel?.font = fontCoreDreamHeavy(fontSize: 25)
        naverLogin.setTitle("NAVER 로그인", for: .normal)
        naverLogin.setTitleColor(.black, for: .normal)
        naverLogin.backgroundColor = .systemGreen
        
        autoLoginButton.setBackgroundImage(UIImage(named: "autologinbox.png"), for: .normal)
        autoLoginButton.setBackgroundImage(UIImage(named: "autologincheck.png"), for: .selected)
        autoLoginButton.tintColor = .clear
        
        autoLoginLabel.font = fontCoreDreamLight(fontSize: 18)
        autoLoginLabel.text = "자동로그인"
    }
    
    // MARK: - 자동 로그인 체크 박스 구현
    @IBAction func clickedAutoLoginBox(_ sender: UIButton) {
        // auto login 선택 여부
        sender.isSelected = !sender.isSelected
//        if sender.isSelected == true{
//            isAutoLogin = true
//        } else {
//            isAutoLogin = false
//        }
    }
    
    // MARK: - 로그인 버튼 클릭 액션
    @IBAction func clickedAppLogin(_ sender: UIButton) {
        
    }
    
    // MARK: - 가입 버튼 클릭 액션
    @IBAction func clickedAppJoin(_ sender: UIButton) {
        // Modal: Present - Dismiss
        // 1. 특정 스토리보드 내 전환할 화면 가져오기
        let moveView = self.storyboard?.instantiateViewController(withIdentifier: "AppJoinTableViewController")
        
        // 1-1. 화면 전환시 전환 애니메이션 설정
    //        moveView.modalTransitionStyle = .coverVertical
        
        // 1-2. 전환된 화면이 나타나는 표현 방식 설정
//            moveView!.modalPresentationStyle = .fullScreen
        
        // 2. 화면 전환하기
        // completion: 화면 전환이 이루어지고 처리하는 부분
        self.present(moveView!, animated: true, completion: nil)
    }
    
    // MARK: - ID 찾기 버튼 클릭 액션
    @IBAction func clickedIdFind(_ sender: UIButton) {
        
    }
    
    // MARK: - PW 찾기 버튼 클릭 액션
    @IBAction func clickedPwFind(_ sender: UIButton) {
        
    }
    
    
}
