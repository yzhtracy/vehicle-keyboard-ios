//
//  KeyboardLayout.swift
//  VehicleKeyboard
//
//  Created by cjz on 2018/9/13.
//  Copyright © 2018年 Xi'an iRain IoT. Technology Service CO., Ltd. All rights reserved.
//

import UIKit

class KeyboardLayout: NSObject {
    
    var row0: Array<Key>?
    var row1: Array<Key>?
    var row2: Array<Key>?
    var row3: Array<Key>?
    var keys: Array<Key>?
    
    //index 当前键盘所处的键盘位置；
    var index = 0
    //presetNumber 当前预设的车牌号码；
    var presetNumber :String?
    //presetNumberType 同numberType；
    var presetNumberType :PlateNumberType?
    //detectedNumberType 检测当前输入车牌号码的号码类型；
    var detectedNumberType :PlateNumberType?
    //numberLength 当前预设的车牌号码长度；
    var numberLength :Int?
    //numberLimitLength 当前车牌号码的最大长度；
    var numberLimitLength :Int?
    
    func rowArray() -> [[Key]] {
        return [self.row0!,self.row1!,self.row2!,self.row3!]
    }
}
