//
//  Config.swift
//  
//
//  Created by lethe(wn-na, lecheln00@gmail.com) on 4/6/25.
//

import Foundation
import UIKit

public struct ProtectionConfig {
    public var screenshot: Bool = false
    public var screenRecord: Bool = false
    public var appSwitcher: Bool = false
}

public class CaptureProtectionConfig {
    public var prevent = ProtectionConfig()
    public var observer = ProtectionConfig()
    public func protectionStatus() -> Int {
        let result =
        (prevent.screenshot ? Constants.CaptureEventType.PREVENT_SCREEN_CAPTURE.rawValue : 0)
        + (prevent.screenRecord ? Constants.CaptureEventType.PREVENT_SCREEN_RECORDING.rawValue : 0)
        + (prevent.appSwitcher ? Constants.CaptureEventType.PREVENT_SCREEN_APP_SWITCHING.rawValue : 0)
        
        if result == 0 {
            return Constants.CaptureEventType.ALLOW.rawValue
        }
        return result
    }
}

public struct ProtectorViewOption {
    public var viewController: UIViewController?
    public var text: String?
    public var textColor: String = "#000000"
    public var backgroundColor: String = "#FFFFFF"
    public var image: UIImage?
    public var type: Constants.CaptureProtectionType = Constants.CaptureProtectionType.NONE
    public var contentMode: UIView.ContentMode = .scaleAspectFit
}

public class ProtectionViewConfig {
    public var secureTextField: UITextField?
    public var screenRecord = ProtectorViewOption()
    public var appSwitcher = ProtectorViewOption()
}

