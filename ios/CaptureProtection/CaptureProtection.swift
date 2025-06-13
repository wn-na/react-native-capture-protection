//
//  CaptureProtection.swift
//
//
//  Created by lethe(wn-na, lecheln00@gmail.com) on 4/6/25.
//

import React
import UIKit
import Foundation

@objc(CaptureProtection)
class CaptureProtection: RCTEventEmitter {
    private var hasListeners = false
    static var config = CaptureProtectionConfig()
    static var protectionViewConfig = ProtectionViewConfig()
    private var protectorTimer: DispatchSourceTimer?
    
    override init() {
        super.init()
        addScreenshotObserver()
        addScreenRecordObserver()
        addAppSwitcherObserver()
        addBundleReloadObserver()
    }
    
    deinit {
        removeBundleReloadObserver()
    }
    
    
    func cancelTimer() {
        if let timer = protectorTimer {
            timer.setEventHandler {}
            timer.cancel()
            protectorTimer = nil
        }
    }
    
    // MARK: - React Native Module Function
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
        eventScreenRecordImmediate()
    }
    
    @objc(stopObserving)
    override func stopObserving() {
        hasListeners = false
    }
    
    @objc func allowScreenshot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            secureScreenshot(isSecure: false)
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenshot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            secureScreenshot(isSecure: true)
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func allowScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.config.prevent.screenRecord = false
            removeScreenRecordView()
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.NONE
            eventScreenRecordImmediate(true)
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenRecordWithText(_ text: String,
                                           textColor: String,
                                           backgroundColor: String,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.TEXT
            CaptureProtection.protectionViewConfig.screenRecord.text = text
            CaptureProtection.protectionViewConfig.screenRecord.textColor = textColor
            CaptureProtection.protectionViewConfig.screenRecord.backgroundColor = backgroundColor
            eventScreenRecordImmediate(true)
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(nil)
        }
    }
    
    @objc func preventScreenRecordWithImage(_ image: NSDictionary,
                                            backgroundColor: String,
                                            contentMode: Double,
                                            resolver: @escaping RCTPromiseResolveBlock,
                                            rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            self.eventScreenRecordImmediate(true)
            sendListener(status: CaptureProtection.config.protectionStatus())
            
            do {
                CaptureProtection.protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.IMAGE
                CaptureProtection.protectionViewConfig.screenRecord.backgroundColor = backgroundColor
               
                CaptureProtection.protectionViewConfig.screenRecord.contentMode = UIView.ContentMode(rawValue: Int(contentMode)) ?? .scaleAspectFit
                if let screenImage = RCTConvert.uiImage(image) {
                    CaptureProtection.protectionViewConfig.screenRecord.image = screenImage
                    resolver(nil)
                } else {
                    throw NSError(domain: "preventScreenRecordWithImage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } catch {
                CaptureProtection.protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.NONE
                rejecter("preventScreenRecordWithImage", error.localizedDescription, error)
            }
        }
    }
    
    @objc func allowAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.config.prevent.appSwitcher = false
            removeAppSwitcherView()
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(nil)
        }
    }
    
    @objc func preventAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.config.prevent.appSwitcher = true
            CaptureProtection.protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.NONE
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(nil)
        }
    }
    
    @objc func preventAppSwitcherWithText(_ text: String,
                                          textColor: String,
                                          backgroundColor: String,
                                          resolver: @escaping RCTPromiseResolveBlock,
                                          rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.config.prevent.appSwitcher = true
            CaptureProtection.protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.TEXT
            CaptureProtection.protectionViewConfig.appSwitcher.text = text
            CaptureProtection.protectionViewConfig.appSwitcher.textColor = textColor
            CaptureProtection.protectionViewConfig.appSwitcher.backgroundColor = backgroundColor
            sendListener(status: CaptureProtection.config.protectionStatus())
            resolver(nil)
        }
    }
    
    @objc func preventAppSwitcherWithImage(_ image: NSDictionary,
                                           backgroundColor: String,
                                           contentMode: Double,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            CaptureProtection.config.prevent.appSwitcher = true
            sendListener(status: CaptureProtection.config.protectionStatus())

            do {
                CaptureProtection.protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.IMAGE
                CaptureProtection.protectionViewConfig.appSwitcher.backgroundColor = backgroundColor
                CaptureProtection.protectionViewConfig.appSwitcher.contentMode = UIView.ContentMode(rawValue: Int(contentMode)) ?? .scaleAspectFit
                if let screenImage = RCTConvert.uiImage(image) {
                    CaptureProtection.protectionViewConfig.appSwitcher.image = screenImage
                    resolver(nil)
                } else {
                    throw NSError(domain: "preventAppSwitcherWithImage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } catch {
                CaptureProtection.protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.NONE
                rejecter("preventAppSwitcherWithImage", error.localizedDescription, error)
            }
        }
    }
    
    @objc func hasListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        resolver(hasListeners)
    }
    
    @objc func protectionStatus(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        resolver([
            "screenshot": CaptureProtection.config.prevent.screenshot,
            "record": CaptureProtection.config.prevent.screenRecord,
            "appSwitcher": CaptureProtection.config.prevent.appSwitcher
        ])
    }
    
    @objc func isScreenRecording(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool {
            resolver(isCaptured)
        } else {
            rejecter("isScreenRecording", "Failed to get screen recording status", nil)
        }
    }
    
    // MARK: - Send Event Listener
    func sendListener(status: Int) {
        if hasListeners {
            self.sendEvent(withName: "CaptureProtectionListener", body: status)
        }
    }
    
    func triggerEvent(_ event: Constants.CaptureEventType) {
        if hasListeners {
            sendListener(status: event.rawValue)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) { [self] in
                if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool, isCaptured == true {
                    sendListener(status: Constants.CaptureEventType.RECORDING.rawValue)
                } else {
                    sendListener(status: Constants.CaptureEventType.UNKNOWN.rawValue)
                }
            }
        }
    }
    
    @objc func eventScreenshot(notification: Notification) {
        self.triggerEvent(Constants.CaptureEventType.CAPTURED)
    }
    
    @objc func eventScreenRecord(notification: Notification, isEvent: Bool = false) {
        if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool {
            if isCaptured {
                if CaptureProtection.config.prevent.screenRecord {
                    secureScreenRecord()
                }
                sendListener(status: Constants.CaptureEventType.RECORDING.rawValue)
            } else {
                removeScreenRecordView()
                if !isEvent {
                    triggerEvent(Constants.CaptureEventType.END_RECORDING)
                }
            }
        }
    }
    
    func eventScreenRecordImmediate(_ prevent: Bool = false) {
        if (prevent) {
            CaptureProtection.config.prevent.screenRecord = true
        }
        eventScreenRecord(notification: Notification(name: Notification.Name("Init")), isEvent: true)
    }
    
    // MARK: - Observer
    private func addScreenshotObserver() {
        guard !CaptureProtection.config.observer.screenshot else { return }
        CaptureProtection.config.observer.screenshot = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenshot(notification:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func removeScreenshotObserver() {
        guard CaptureProtection.config.observer.screenshot else { return }
        CaptureProtection.config.observer.screenshot = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func addScreenRecordObserver() {
        guard !CaptureProtection.config.observer.screenRecord else { return }
        CaptureProtection.config.observer.screenRecord = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenRecord), name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func removeScreenRecordObserver() {
        guard CaptureProtection.config.observer.screenRecord else { return }
        CaptureProtection.config.observer.screenRecord = false
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func addAppSwitcherObserver() {
        guard !CaptureProtection.config.observer.appSwitcher else { return }
        CaptureProtection.config.observer.appSwitcher = true
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureAppSwitcher()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.secureAppSwitcher()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.removeAppSwitcherView()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { [weak self] _ in
            DispatchQueue.main.async {
                self?.removeAppSwitcherView()
            }
        }
    }
    
    private func removeBackgroundObserver() {
        guard CaptureProtection.config.observer.appSwitcher else { return }
        CaptureProtection.config.observer.appSwitcher = false
        DispatchQueue.main.async {
            self.removeAppSwitcherView()
        }
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func addBundleReloadObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.RCTTriggerReloadCommand, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.async {
                self?.cancelTimer()
                if let secureTextField = CaptureProtection.protectionViewConfig.secureTextField {
                    secureTextField.isSecureTextEntry = false
                }
                
                self?.secureScreenshot(isSecure: false)
                self?.removeScreenshotObserver()
                self?.removeScreenRecordObserver()
                self?.removeBackgroundObserver()
                self?.removeBundleReloadObserver()
            }
        }
    }

    private func removeBundleReloadObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.RCTTriggerReloadCommand, object: nil)
    }
    // MARK: - Protection UI with ScreenShot
    @objc func secureScreenshot(isSecure: Bool) {
        CaptureProtection.config.prevent.screenshot = isSecure
        if isSecure == false {
            DispatchQueue.main.async {
                CaptureProtection.protectionViewConfig.secureTextField?.isSecureTextEntry = false
            }
            return
        } else {
            if CaptureProtection.protectionViewConfig.secureTextField == nil {
                DispatchQueue.main.async {
                    if CaptureProtection.protectionViewConfig.secureTextField == nil {
                        CaptureProtection.protectionViewConfig.secureTextField = UITextField.init()
                        CaptureProtection.protectionViewConfig.secureTextField!.isUserInteractionEnabled = false
                        CaptureProtection.protectionViewConfig.secureTextField!.tag = Constants.TAG_SCREENSHOT_PROTECTION
                        CaptureProtection.protectionViewConfig.secureTextField!.isSecureTextEntry = true
                        if let window = UIApplication.shared.delegate?.window {
                            window?.makeKeyAndVisible()
                            
                            window?.layer.superlayer?.addSublayer(CaptureProtection.protectionViewConfig.secureTextField!.layer)
                            CaptureProtection.protectionViewConfig.secureTextField?.layer.sublayers?.first?.addSublayer(window!.layer)
                            CaptureProtection.protectionViewConfig.secureTextField?.layer.sublayers?.last?.addSublayer(window!.layer)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    CaptureProtection.protectionViewConfig.secureTextField?.isSecureTextEntry = true
                }
            }
        }
    }
    
    // MARK: - Protection UI with ScreenRecord
    private func secureScreenRecord() {
        removeScreenRecordView()
        if CaptureProtection.config.prevent.screenRecord {
            DispatchQueue.main.async {
                let config = CaptureProtection.protectionViewConfig.screenRecord
                if config.type == Constants.CaptureProtectionType.TEXT {
                    CaptureProtection.protectionViewConfig.screenRecord.viewController = UIViewUtils.textView(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        text: config.text!,
                        textColor: config.textColor,
                        backgroundColor: config.backgroundColor)
                } else if config.type == Constants.CaptureProtectionType.IMAGE {
                    CaptureProtection.protectionViewConfig.screenRecord.viewController = UIViewUtils.imageView(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        image: config.image!,
                        backgroundColor: config.backgroundColor,
                        contentMode: config.contentMode)
                } else {
                    CaptureProtection.protectionViewConfig.screenRecord.viewController = UIViewUtils.view(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        backgroundColor: config.backgroundColor
                    )
                }

                let protectionWindow = UIWindow(frame: UIScreen.main.bounds)
                protectionWindow.windowLevel = .alert + 1
                protectionWindow.backgroundColor = .clear
                protectionWindow.rootViewController = CaptureProtection.protectionViewConfig.screenRecord.viewController
                protectionWindow.makeKeyAndVisible()
                CaptureProtection.protectionViewConfig.screenRecord.window = protectionWindow
            }
        }
    }

    private func removeScreenRecordView() {
        CaptureProtection.protectionViewConfig.screenRecord.window?.isHidden = true
        CaptureProtection.protectionViewConfig.screenRecord.window = nil
    }

    // MARK: - Protection UI with App Swither
    private func secureAppSwitcher() {
        removeAppSwitcherView() { [self] in
            if CaptureProtection.config.prevent.appSwitcher {
                protectorTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
                protectorTimer!.schedule(deadline: .now() + 0.05)
                protectorTimer!.setEventHandler {
                    DispatchQueue.main.async {
                        let config = CaptureProtection.protectionViewConfig.appSwitcher
                        if config.type == Constants.CaptureProtectionType.TEXT {
                            CaptureProtection.protectionViewConfig.appSwitcher.viewController = UIViewUtils.textView(tag: Constants.TAG_APP_SWITCHER_PROTECTION, text: config.text!, textColor: config.textColor, backgroundColor: config.backgroundColor)
                        } else if config.type == Constants.CaptureProtectionType.IMAGE {
                            CaptureProtection.protectionViewConfig.appSwitcher.viewController = UIViewUtils.imageView(tag: Constants.TAG_APP_SWITCHER_PROTECTION, image: config.image!, backgroundColor: config.backgroundColor, contentMode: config.contentMode)
                        } else {
                            CaptureProtection.protectionViewConfig.appSwitcher.viewController = UIViewUtils.view(
                                tag: Constants.TAG_APP_SWITCHER_PROTECTION,
                                backgroundColor: config.backgroundColor
                            )
                        }

                        let protectionWindow = UIWindow(frame: UIScreen.main.bounds)
                        protectionWindow.windowLevel = .alert + 1
                        protectionWindow.backgroundColor = .clear
                        protectionWindow.rootViewController = CaptureProtection.protectionViewConfig.appSwitcher.viewController
                        protectionWindow.makeKeyAndVisible()
                        CaptureProtection.protectionViewConfig.appSwitcher.window = protectionWindow
                    }
                }
                protectorTimer!.resume()
            }
        }
    }

    private func removeAppSwitcherView(completion: (() -> Void)? = nil) {
        self.cancelTimer()
        CaptureProtection.protectionViewConfig.appSwitcher.window?.isHidden = true
        CaptureProtection.protectionViewConfig.appSwitcher.window = nil
        completion?()
    }
}
