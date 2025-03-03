//
//  TextUtils.swift
//  CaptureProtection
//
//  Created by lethe on 3/3/25.
//  Copyright © 2025 Facebook. All rights reserved.
//

import UIKit
import Foundation

public class TextUtils {
    public static func colorFromHexString(hexString: String) -> UIColor {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }
        
        guard hex.count == 6, let rgbValue = UInt64(hex, radix: 16) else {
            return .black
        }
        
        let red = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgbValue & 0xFF) / 255.0
        
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

