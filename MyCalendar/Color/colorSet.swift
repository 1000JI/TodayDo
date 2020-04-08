//
//  colorSet.swift
//  MyCalendar
//
//  Created by 천지운 on 2019/10/28.
//  Copyright © 2019 jwcheon. All rights reserved.
//

import Foundation
import DynamicColor

//var gradient : DynamicGradient = DynamicGradient(colors: [UIColor().customGreen, UIColor().customRed, UIColor().customYellow, UIColor().customBlue, UIColor().customPink, UIColor.black, UIColor.gray, UIColor.purple, UIColor.brown, UIColor.cyan])
//var rgbPalette : [DynamicColor] = gradient.colorPalette(amount: 28)

var gradient : DynamicGradient = DynamicGradient(colors: [UIColor.red, UIColor.orange, UIColor.brown, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue, UIColor.purple, UIColor.magenta, UIColor.white, UIColor.gray, UIColor.black])
var rgbPalette : [DynamicColor] = gradient.colorPalette(amount: 63)
