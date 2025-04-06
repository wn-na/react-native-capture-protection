//
//  Created by lethe(wn-na, lecheln00@gmail.com) on 3/3/25.
//  Copyright © 2025 Facebook. All rights reserved.
//

import Foundation

public class Constants {
    public enum CaptureEventType: Int {
        case NONE = 0
        case RECORDING = 1
        case END_RECORDING = 2
        case CAPTURED = 3
        case APP_SWITCHING = 4
        case UNKNOWN = 5
        case ALLOW = 8
        case PREVENT_SCREEN_CAPTURE = 16
        case PREVENT_SCREEN_RECORDING = 32
        case PREVENT_SCREEN_APP_SWITCHING = 64
    }

    public enum CaptureProtectionType: Int {
        case NONE = 0
        case TEXT = 1
        case IMAGE = 2
    }
    
    static let TAG_RECORD_PROTECTION_SCREEN = -1002
    static let TAG_SCREENSHOT_PROTECTION = -1004
    static let TAG_APP_SWITCHER_PROTECTION = -1005
}
