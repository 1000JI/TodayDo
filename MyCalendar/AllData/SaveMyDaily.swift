//
//  SaveMyDaily.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/17.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import Foundation
import UIKit

var allDailySave    : [MyDaily]         = []    // 모든 일정 저장
var monthDailySave  : [MyDaily]         = []    // 해당 월 일정 저장
var myDailyIndex    : Int               = 0     // 글번호(PK)
var calendarData    : [DateColorClass]  = []    // 캘린더에 표시할 배열
var holidaySave     : [MyHoliday]       = []    // 공휴일 저장

class MyDaily {
    var dailyNum        : Int?
    var dailyTitle      : String?
    var dailyDate       : Date?
    var dailyCategory   : Int?
    var dailyContents   : String?
    var dailyImage      : String?
}

class DateColorClass {
    var date        : String?
    var dateCount   : Int       = 0
    var colorArr    : [UIColor] = []
    var writeNum    : [Int]     = []
}

class MyHoliday {
    var holidayName : String?
    var holidayIs   : String?
    var holidayDate : String?
}

