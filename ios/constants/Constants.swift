//
//  StatusCode.swift
//  CaptureProtection
//
//  Created by lethe on 3/3/25.
//  Copyright © 2025 Facebook. All rights reserved.
//

import Foundation

public class Constants {
    public enum CaptureProtectionStatus: Int {
        case INIT_RECORD_LISTENER = 0
        case REMOVE_RECORD_LISTENER = 1
        case RECORD_LISTENER_NOT_EXIST = 2
        case RECORD_LISTENER_EXIST = 3
        case RECORD_DETECTED_START = 4
        case RECORD_DETECTED_END = 5
        case CAPTURE_DETECTED = 6
        case UNKNOWN = 7
    }
    
    static let TAG_RECORD_PROTECTION_SCREEN = -1002
    static let TAG_SCREEN_PROTECTION = -1004
}
