//
//  TextUtils.swift
//  CaptureProtection
//
//  Created by lethe on 3/3/25.
//  Copyright © 2025 Facebook. All rights reserved.
//

import UIKit
import Foundation

public class EventUtils {
    public static func eventMessage(status: Constants.CaptureProtectionStatus, isPreventScreenshot: Bool, isPreventScreenRecord: Bool) -> [String: Any] {
        return [
            "status": status.rawValue,
            "isPrevent": [
                "screenshot": isPreventScreenshot,
                "record": isPreventScreenRecord
            ]
        ]
    }
}
