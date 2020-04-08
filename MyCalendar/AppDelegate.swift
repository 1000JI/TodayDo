//
//  AppDelegate.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/16.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import UIKit
import RealmSwift
import GoogleMobileAds
import StoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?
    
    var realmSettingTable   : Results<MySettingTable>!  // 내 세팅 테이블
    var realmDailyTable     : Results<MyDailyTable>!    // 내 일정 테이블
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Google AD
        GADMobileAds.sharedInstance().start(completionHandler: nil)
        
        // Inside your application(application:didFinishLaunchingWithOptions:)
        Realm.Configuration.defaultConfiguration = Realm.Configuration(
            schemaVersion: 5,   // 디비 업데이트하면 숫자 증가
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {
                    // The enumerateObjects(ofType:_:) method iterates
                    // over every Person object stored in the Realm file
                    migration.enumerateObjects(ofType: MyDailyTable.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        newObject!["dailyComplete"] = false
                    }
                }
                if (oldSchemaVersion < 2) {
                    migration.enumerateObjects(ofType: MyDailyTable.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        newObject!["dailyAlertOn"] = false
                        newObject!["dailyAlertDate"] = ""
                    }
                }
                if (oldSchemaVersion < 3) {
                    migration.enumerateObjects(ofType: MySettingTable.className()) { (oldObject, newObject) in
                        newObject!["holidayList"] = List<Int>()
                    }
                }
                if (oldSchemaVersion < 4) {
                    migration.enumerateObjects(ofType: MyDailyTable.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        newObject!["dailyIsHoliday"] = 0
                    }
                }
                if (oldSchemaVersion < 5) {
                    migration.enumerateObjects(ofType: MySettingTable.className()) { oldObject, newObject in
                        // combine name fields into a single field
                        newObject!["indexHoliday"]      = SaveBasicColor.HolidayColor
                        newObject!["indexSaturday"]     = SaveBasicColor.SaturdayColor
                        newObject!["indexDefault"]      = SaveBasicColor.DefaultColor
                        newObject!["indexTodayColor"]   = SaveBasicColor.TodayColor
                        newObject!["indexSelectColor"]  = SaveBasicColor.SelectColor
                    }
                }
            }
        )
        
        let realm = try! Realm()
        realmSettingTable = realm.objects(MySettingTable.self)

        // 세팅 데이터가 없을 경우
        if realmSettingTable.count == 0 {
//            print("no setting")

            try! realm.write {
                let settingTable = MySettingTable()
                settingTable.userNumber = 0
                settingTable.dailyLimitCount = 15

                realm.add(settingTable)
            }
        } else {
//            print(realmSettingTable[0].dailyLimitCount)
        }
        
        let plist = UserDefaults.standard
        plist.set(0,        forKey: "selectCount")
        plist.set("all",    forKey: "selectDate")
        plist.set("\(Date().year)-\(Date().month)", forKey: "presentDate")
        
        // 원격 알림 시스템에 앱을 등록
        if #available(iOS 10.0, *) {
          // For iOS 10 display notification (sent via APNS)
          UNUserNotificationCenter.current().delegate = self

          let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
          UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        } else {
            let settings: UIUserNotificationSettings =
            UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            application.registerUserNotificationSettings(settings)
        }

        application.registerForRemoteNotifications()
        
        // Badge 초기화
//        UIApplication.shared.applicationIconBadgeNumber = 0
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        sleep(1)
        
        // Override point for customization after application launch.
        return true
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    // 앱이 background 상태일 때 실행
    func applicationDidEnterBackground(_ application: UIApplication) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    // 앱이 background에서 foreground로 이동
    func applicationWillEnterForeground(_ application: UIApplication) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    // 앱이 active 에서 inactive로 이동될 때 실행
    func applicationWillResignActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    // 앱이 active상태가 되어 실행 중일 때
    func applicationDidBecomeActive(_ application: UIApplication) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
    }
    
    // MARK: date formatter
    fileprivate lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-M-d"
        formatter.locale = Locale(identifier:"ko_KR")
        formatter.timeZone = TimeZone(abbreviation: "KST")
        return formatter
    }()

    // MARK: UISceneSession Lifecycle
    @available (iOS 13.0, *)
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
    
    @available (iOS 13.0, *)
    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    
    // (앱이 켜져 있는 상태)포르가운드에서도 알림을 받을 수 있게 설정
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)
    {
        completionHandler([.alert, .badge, .sound])
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "refreshData"), object: nil, userInfo: nil)
        UIApplication.shared.applicationIconBadgeNumber = getTodayCount()
        
        completionHandler()
    }
}
