import React
import UIKit
import Foundation

@objc(CaptureProtection)
class CaptureProtection: RCTEventEmitter {
    private var hasListeners = false
    private var hasScreenRecordObserver = false
    private var hasScreenshotObserver = false
    private var isPreventScreenRecord = false
    private var isPreventScreenshot = false
    private var isBundleObserver = false
    private var isBackgroundObserver = false
    private var isPreventBackground = false
    
    private var secureTextField: UITextField?
    private var protecterViewController: UIViewController?
    private var protecterScreenViewController: UIViewController?
    private var text: String?
    private var textColor: String?
    private var backgroundColor: String?
    private var backgroundScreenColor: String?
    
    
    @objc(supportedEvents)
    override func supportedEvents() -> [String] {
        ["CaptureProtectionListener"]
    }
    
    @objc(requiresMainQueueSetup)
    override static func requiresMainQueueSetup() -> Bool {
        false
    }
    
    @objc(startObserving)
    override func startObserving() {
        hasListeners = true
    }
    
    @objc(stopObserving)
    override func stopObserving() {
        hasListeners = false
    }
    
    func setScreenRecordScreen(withImage image: UIImage) {
        guard let window = UIApplication.shared.delegate?.window ?? nil else { return }
        
        let protectorVC = UIViewController()
        protectorVC.view.tag = Constants.TAG_RECORD_PROTECTION_SCREEN
        
        let imageView = UIImageView(image: image)
        imageView.frame = window.frame
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        
        protectorVC.view.addSubview(imageView)
        protectorVC.view.backgroundColor = .white
        
        self.protecterViewController = protectorVC
    }
    
    func createRecordProtectionScreen(withText text: String,
                                      textColor: String,
                                      backgroundColor: String) {
        self.text = text
        self.textColor = textColor
        self.backgroundColor = backgroundColor
        
        guard let window = UIApplication.shared.delegate?.window ?? nil else { return }
        
        if let captureProtectScreenController = window.viewWithTag(Constants.TAG_RECORD_PROTECTION_SCREEN)?.next as? UIViewController {
            captureProtectScreenController.willMove(toParent: nil)
            captureProtectScreenController.view.removeFromSuperview()
            captureProtectScreenController.removeFromParent()
        }
        
        if let existingController = self.protecterViewController {
            existingController.willMove(toParent: nil)
            existingController.view.removeFromSuperview()
            existingController.removeFromParent()
        }
        
        let protectorVC = UIViewController()
        protectorVC.view.tag = Constants.TAG_RECORD_PROTECTION_SCREEN
        protectorVC.view.backgroundColor = TextUtils.colorFromHexString(hexString: self.backgroundColor!)
        
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = TextUtils.colorFromHexString(hexString: self.textColor!)
        label.isUserInteractionEnabled = false
        label.text = self.text
        label.frame = window.frame
        
        protectorVC.view.addSubview(label)
        self.protecterViewController = protectorVC
    }
    
    @objc func eventScreenshot(notification: Notification) {
        if hasListeners {
            self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .CAPTURE_DETECTED, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
        }
    }
    
    @objc func eventScreenRecord(notification: Notification) {
        eventScreenRecordWithInit(notification: notification, _init: false)
    }
    
    private func eventScreenRecordWithInit(notification: Notification, _init: Bool) {
        if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool {
            if isCaptured {
                if isPreventScreenRecord {
                    createRecordProtectionScreen()
                }
                if hasListeners {
                    self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .RECORD_DETECTED_START, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
                }
            } else {
                removeRecordProtectionScreen()
                if !_init {
                    if hasListeners {
                        self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .RECORD_DETECTED_END, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
                    }
                }
            }
        }
    }
    
    private func bundleObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.RCTBridgeWillReload, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureTextField?.isSecureTextEntry = false
                self?.removeScreenShotObserver()
                self?.removeScreenRecordObserver()
                self?.protecterViewController = nil
                self?.hasScreenRecordObserver = false
                self?.hasScreenshotObserver = false
                self?.isPreventScreenRecord = false
                self?.isPreventScreenshot = false
            }
        }
    }
    
    private func addBackgroundObserver() {
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureBackgroundView(show: true)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureBackgroundView(show: true)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureBackgroundView(show: false)
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureBackgroundView(show: false)
            }
        }
    }
    
    private func secureBackgroundView(show: Bool) {
        DispatchQueue.main.async {
            if self.protecterScreenViewController != nil {
                self.protecterScreenViewController?.willMove(toParent: nil)
                self.protecterScreenViewController?.view.removeFromSuperview()
                self.protecterScreenViewController?.removeFromParent()
            }
            
            if !self.isPreventBackground {
                return
            }
            
            if show {
                let viewController = UIViewController()
                viewController.view.backgroundColor = UIColor.red
                self.protecterScreenViewController = viewController
                viewController.view.backgroundColor = TextUtils.colorFromHexString(hexString: self.backgroundScreenColor ?? "#ffffff")
                if let window = UIApplication.shared.delegate?.window {
                    window?.addSubview(viewController.view)
                }
            }
        }
    }
    
    private func createRecordProtectionScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.delegate?.window else { return }
            if let existingViewController = window?.viewWithTag(Constants.TAG_RECORD_PROTECTION_SCREEN)?.next as? UIViewController {
                existingViewController.view.removeFromSuperview()
                existingViewController.removeFromParent()
            }
            
            if self.protecterViewController != nil {
                self.protecterViewController?.view.removeFromSuperview()
                self.protecterViewController?.removeFromParent()
            }
            
            self.protecterViewController = UIViewController()
            self.protecterViewController?.view.tag = Constants.TAG_RECORD_PROTECTION_SCREEN
            self.protecterViewController?.view.backgroundColor = TextUtils.colorFromHexString(hexString: self.backgroundColor ?? "#ffffff")
            
            let label = UILabel()
            label.textAlignment = .center
            label.textColor = TextUtils.colorFromHexString(hexString: self.textColor ?? "#000000")
            label.text = self.text ?? "Record Detected"
            label.frame = window?.frame ?? CGRect.zero
            self.protecterViewController?.view.addSubview(label)
            
            if let rootViewController = window?.rootViewController {
                rootViewController.addChild(self.protecterViewController!)
                rootViewController.view.addSubview(self.protecterViewController!.view)
                window?.makeKeyAndVisible()
                self.protecterViewController?.didMove(toParent: rootViewController)
            }
            
            
            
        }
    }
    
    private func removeRecordProtectionScreen() {
        DispatchQueue.main.async {
            guard let window = UIApplication.shared.delegate?.window else { return }
            if let existingViewController = window?.viewWithTag(Constants.TAG_RECORD_PROTECTION_SCREEN)?.next as? UIViewController {
                existingViewController.willMove(toParent: nil)
                existingViewController.view.removeFromSuperview()
                existingViewController.removeFromParent()
            }
        }
    }
    
    @objc func allowScreenshot(_ removeScreenshotListener: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.secureScreenshotView(isSecure: false)
            if removeScreenshotListener {
                self.removeScreenShotObserver()
            }
            self.isPreventBackground = false
            self.isPreventScreenshot = false
            if self.hasListeners {
                self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .UNKNOWN, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
            }
            resolver(true)
        }
    }
    
    @objc func preventScreenshot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.secureScreenshotView(isSecure: true)
            self.addScreenShotObserver()
            self.isPreventBackground = true
            self.isPreventScreenshot = true
            if self.hasListeners {
                self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .UNKNOWN, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
            }
            resolver(true)
        }
    }
    
    private func secureScreenshotView(isSecure: Bool) {
        DispatchQueue.main.async {
            if !self.isBundleObserver {
                self.isBundleObserver = true
                self.bundleObserver()
            }
            if !self.isBackgroundObserver {
                self.isBackgroundObserver = true
                self.addBackgroundObserver()
            }
            
            if self.secureTextField == nil {
                self.secureTextField = UITextField()
                self.secureTextField?.isUserInteractionEnabled = false
                self.secureTextField?.tag = Constants.TAG_SCREEN_PROTECTION
                if let window = UIApplication.shared.delegate?.window {
                    window?.makeKeyAndVisible()
                    
                    
                    window?.layer.superlayer?.addSublayer(self.secureTextField!.layer)
                    
                    self.secureTextField?.layer.sublayers?.first?.addSublayer(window!.layer)
                    self.secureTextField?.layer.sublayers?.last?.addSublayer(window!.layer)
                    
                }
                
            }
            
            self.secureTextField?.isSecureTextEntry = isSecure
        }
    }
    
    @objc func preventScreenRecord(_ isImmediate: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.isPreventScreenRecord = true
            if isImmediate {
                self.eventScreenRecordWithInit(notification: Notification(name: Notification.Name("Test")), _init: true)
            }
            if self.hasListeners {
                self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .UNKNOWN, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
            }
            resolver(true)
        }
    }
    
    @objc func allowScreenRecord(_ removeScreenRecordListener: Bool, resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.isPreventScreenRecord = false
            if (removeScreenRecordListener) {
                self.removeScreenRecordObserver()
            }
            self.removeRecordProtectionScreen()
            if self.hasListeners {
                self.sendEvent(withName: "CaptureProtectionListener", body: EventUtils.eventMessage(status: .UNKNOWN, isPreventScreenshot: self.isPreventScreenshot, isPreventScreenRecord: self.isPreventScreenRecord))
            }
            resolver(true)
        }
    }
    
    @objc func resetAll(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.removeRecordProtectionScreen()
            self.removeScreenShotObserver()
            self.removeScreenRecordObserver()
            resolver(true)
        }
    }
    
    private func addScreenShotObserver() {
        guard !self.hasScreenshotObserver else { return }
        self.hasScreenshotObserver = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenshot(notification:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func removeScreenShotObserver() {
        guard self.hasScreenshotObserver else { return }
        self.hasScreenshotObserver = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func addScreenRecordObserver() {
        guard !self.hasScreenRecordObserver else { return }
        self.hasScreenRecordObserver = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenRecord(notification:)), name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func removeScreenRecordObserver() {
        guard self.hasScreenRecordObserver else { return }
        self.hasScreenRecordObserver = false
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    @objc func addScreenshotListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.addScreenShotObserver()
            resolver(true)
        }
    }
    
    @objc func removeScreenshotListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.removeScreenShotObserver()
            resolver(true)
        }
    }
    
    @objc func addScreenRecordListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.addScreenRecordObserver()
            resolver(true)
        }
    }
    
    @objc func removeScreenRecordListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.removeScreenRecordObserver()
            resolver(true)
        }
    }
    
    @objc func getPreventStatus(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        resolver([
            "screenshot": isPreventScreenshot,
            "record": isPreventScreenRecord
        ])
    }
    
    @objc func isScreenRecording(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        if let screen = UIScreen.main.value(forKey: "isCaptured") as? Bool {
            resolver(screen)
        } else {
            rejecter("SCREEN_RECORDING_ERROR", "Failed to get screen recording status", nil)
        }
    }
    
    @objc func hasListener(_ resolver: @escaping RCTPromiseResolveBlock,
                           rejecter: @escaping RCTPromiseRejectBlock) {
        let result: [String: Bool] = [
            "screenshot": self.hasScreenshotObserver,
            "record": self.hasScreenRecordObserver
        ]
        resolver(result)
    }
    
    @objc func allowBackground(_ resolver: @escaping RCTPromiseResolveBlock,
                               rejecter: @escaping RCTPromiseRejectBlock) {
        isPreventBackground = false
        resolver(nil)
    }
    
    @objc func preventBackground(_ backgroundColor: String,
                                 resolver: @escaping RCTPromiseResolveBlock,
                                 rejecter: @escaping RCTPromiseRejectBlock) {
        isPreventBackground = true
        self.backgroundScreenColor = backgroundColor
        resolver(nil)
    }
    
    @objc func setScreenRecordScreenWithImage(_ screenImage: NSDictionary,
                                              resolver: @escaping RCTPromiseResolveBlock,
                                              rejecter: @escaping RCTPromiseRejectBlock) {
        print("[CaptureProtection] Call setScreenRecordScreenWithImage")
        
        DispatchQueue.main.async {
            do {
                if let image = RCTConvert.uiImage(screenImage) {
                    self.setScreenRecordScreen(withImage: image)
                    resolver(true)
                } else {
                    throw NSError(domain: "setScreenRecordScreenWithImage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } catch {
                rejecter("setScreenRecordScreenWithImage", error.localizedDescription, error)
            }
        }
    }
    
    @objc func setScreenRecordScreenWithText(_ screenText: String,
                                             textColor: String,
                                             backgroundColor: String,
                                             resolver: @escaping RCTPromiseResolveBlock,
                                             rejecter: @escaping RCTPromiseRejectBlock) {
        print("[CaptureProtection] Call setScreenRecordScreenWithText")
        
        DispatchQueue.main.async {
            do {
                self.createRecordProtectionScreen(withText: screenText, textColor: textColor, backgroundColor: backgroundColor)
                resolver(true)
            } catch {
                rejecter("setScreenRecordScreenWithText", error.localizedDescription, error)
            }
        }
    }
}
