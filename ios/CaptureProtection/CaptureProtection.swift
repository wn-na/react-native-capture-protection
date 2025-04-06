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
    private var config = CaptureProtectionConfig()
    private var protectionViewConfig = ProtectionViewConfig()
    
    override init() {
        super.init()
        DispatchQueue.main.async { [self] in
            addScreenshotObserver()
            addScreenRecordObserver()
            addAppSwitcherObserver()
            addBundleReloadObserver()
        }
    }

    deinit {
        removeScreenshotObserver()
        removeScreenRecordObserver()
        removeBackgroundObserver()
        removeBundleReloadObserver()
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
            sendListener(status: config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenshot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            secureScreenshot(isSecure: true)
            sendListener(status: config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func allowScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            config.prevent.screenRecord = false
            removeScreenRecordView()
            sendListener(status: config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.NONE
            eventScreenRecordImmediate(true)
            sendListener(status: config.protectionStatus())
            resolver(true)
        }
    }
    
    @objc func preventScreenRecordWithText(_ text: String,
                                           textColor: String,
                                           backgroundColor: String,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.TEXT
            protectionViewConfig.screenRecord.text = text
            protectionViewConfig.screenRecord.textColor = textColor
            protectionViewConfig.screenRecord.backgroundColor = backgroundColor
            eventScreenRecordImmediate(true)
            sendListener(status: config.protectionStatus())
            resolver(nil)
        }
    }
    
    @objc func preventScreenRecordWithImage(_ image: NSDictionary,
                                            resolver: @escaping RCTPromiseResolveBlock,
                                            rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            self.eventScreenRecordImmediate(true)
            sendListener(status: config.protectionStatus())
            
            do {
                protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.IMAGE
                if let screenImage = RCTConvert.uiImage(image) {
                    protectionViewConfig.screenRecord.image = screenImage
                    resolver(nil)
                } else {
                    throw NSError(domain: "preventScreenRecordWithImage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } catch {
                protectionViewConfig.screenRecord.type = Constants.CaptureProtectionType.NONE
                rejecter("preventScreenRecordWithImage", error.localizedDescription, error)
            }
        }
    }
    
    @objc func allowAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        config.prevent.appSwitcher = false
        removeAppSwitcherView()
        sendListener(status: config.protectionStatus())
        resolver(nil)
    }
    
    @objc func preventAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        config.prevent.appSwitcher = true
        protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.NONE
        sendListener(status: config.protectionStatus())
        resolver(nil)
    }
    
    @objc func preventAppSwitcherWithText(_ text: String,
                                          textColor: String,
                                          backgroundColor: String,
                                          resolver: @escaping RCTPromiseResolveBlock,
                                          rejecter: @escaping RCTPromiseRejectBlock) {
        config.prevent.appSwitcher = true
        protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.TEXT
        protectionViewConfig.appSwitcher.text = text
        protectionViewConfig.appSwitcher.textColor = textColor
        protectionViewConfig.appSwitcher.backgroundColor = backgroundColor
        sendListener(status: config.protectionStatus())
        resolver(nil)
    }
    
    @objc func preventAppSwitcherWithImage(_ image: NSDictionary,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async { [self] in
            config.prevent.appSwitcher = true
            sendListener(status: config.protectionStatus())

            do {
                protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.IMAGE
                if let screenImage = RCTConvert.uiImage(image) {
                    protectionViewConfig.appSwitcher.image = screenImage
                    resolver(nil)
                } else {
                    throw NSError(domain: "preventAppSwitcherWithImage", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid image data"])
                }
            } catch {
                protectionViewConfig.appSwitcher.type = Constants.CaptureProtectionType.NONE
                rejecter("preventAppSwitcherWithImage", error.localizedDescription, error)
            }
        }
    }
    
    @objc func hasListener(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        resolver(hasListeners)
    }
    
    @objc func protectionStatus(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        resolver([
            "screenshot": config.prevent.screenshot,
            "record": config.prevent.screenRecord,
            "appSwitcher": config.prevent.appSwitcher
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
                if config.prevent.screenRecord {
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
            config.prevent.screenRecord = true
        }
        eventScreenRecord(notification: Notification(name: Notification.Name("Init")), isEvent: true)
    }
    
    // MARK: - Observer
    private func addScreenshotObserver() {
        guard !config.observer.screenshot else { return }
        config.observer.screenshot = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenshot(notification:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func removeScreenshotObserver() {
        guard config.observer.screenshot else { return }
        config.observer.screenshot = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func addScreenRecordObserver() {
        guard !config.observer.screenRecord else { return }
        config.observer.screenRecord = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenRecord), name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func removeScreenRecordObserver() {
        guard config.observer.screenRecord else { return }
        config.observer.screenRecord = false
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func addAppSwitcherObserver() {
        guard !config.observer.appSwitcher else { return }
        config.observer.appSwitcher = true
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
        guard self.config.observer.appSwitcher else { return }
        config.observer.appSwitcher = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    private func addBundleReloadObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.RCTBridgeWillReload, object: nil, queue: nil) { [weak self] _ in
            self?.removeScreenshotObserver()
            self?.removeScreenRecordObserver()
            self?.removeBackgroundObserver()
            
            self?.secureScreenshot(isSecure: false)
            self?.removeScreenRecordView()
            self?.removeAppSwitcherView()
            
            self!.protectionViewConfig = ProtectionViewConfig()
            self!.config = CaptureProtectionConfig()
        }
    }

    private func removeBundleReloadObserver() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.RCTBridgeWillReload, object: nil)
    }
    
    // MARK: - Protection UI with ScreenShot
    private func secureScreenshot(isSecure: Bool) {
        config.prevent.screenshot = isSecure
        DispatchQueue.main.async { [self] in
            if protectionViewConfig.secureTextField == nil {
                protectionViewConfig.secureTextField = UITextField()
                protectionViewConfig.secureTextField?.isUserInteractionEnabled = false
                protectionViewConfig.secureTextField?.tag = Constants.TAG_SCREENSHOT_PROTECTION
                protectionViewConfig.secureTextField?.isSecureTextEntry = isSecure
                if let window = UIApplication.shared.delegate?.window {
                    window?.makeKeyAndVisible()
                    window?.layer.superlayer?.addSublayer(protectionViewConfig.secureTextField!.layer)
                    protectionViewConfig.secureTextField?.layer.sublayers?.first?.addSublayer(window!.layer)
                    protectionViewConfig.secureTextField?.layer.sublayers?.last?.addSublayer(window!.layer)
                }
            }
            protectionViewConfig.secureTextField?.isSecureTextEntry = isSecure
        }
    }
    
    // MARK: - Protection UI with ScreenRecord
    private func secureScreenRecord() {
        removeScreenRecordView()
        if config.prevent.screenRecord {
            DispatchQueue.main.async { [self] in
                let config = protectionViewConfig.screenRecord
                if config.type == Constants.CaptureProtectionType.TEXT {
                    protectionViewConfig.screenRecord.viewController = UIViewUtils.textView(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        text: config.text!,
                        textColor: config.textColor,
                        backgroundColor: config.backgroundColor)
                } else if config.type == Constants.CaptureProtectionType.IMAGE {
                    protectionViewConfig.screenRecord.viewController = UIViewUtils.imageView(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        image: config.image!)
                } else {
                    protectionViewConfig.screenRecord.viewController = UIViewUtils.view(
                        tag: Constants.TAG_RECORD_PROTECTION_SCREEN,
                        backgroundColor: config.backgroundColor
                    )
                }
                if let window = UIApplication.shared.delegate?.window {
                    window?.addSubview(protectionViewConfig.screenRecord.viewController!.view)
                }
            }
        }
    }
    
    private func removeScreenRecordView() {
        UIViewUtils.remove(viewController: protectionViewConfig.screenRecord.viewController)
    }
    
    // MARK: - Protection UI with App Swither
    private func secureAppSwitcher() {
        removeAppSwitcherView()
        if config.prevent.appSwitcher {
            DispatchQueue.main.async { [self] in
                let config = protectionViewConfig.appSwitcher
                if config.type == Constants.CaptureProtectionType.TEXT {
                    protectionViewConfig.appSwitcher.viewController = UIViewUtils.textView(tag: Constants.TAG_APP_SWITCHER_PROTECTION, text: config.text!, textColor: config.textColor, backgroundColor: config.backgroundColor)
                } else if config.type == Constants.CaptureProtectionType.IMAGE {
                    protectionViewConfig.appSwitcher.viewController = UIViewUtils.imageView(tag: Constants.TAG_APP_SWITCHER_PROTECTION, image: config.image!)
                } else {
                    protectionViewConfig.appSwitcher.viewController = UIViewUtils.view(
                        tag: Constants.TAG_APP_SWITCHER_PROTECTION,
                        backgroundColor: config.backgroundColor
                    )
                }
                if let window = UIApplication.shared.delegate?.window {
                    window?.addSubview(protectionViewConfig.appSwitcher.viewController!.view)
                }
            }
        }
    }
    
    private func removeAppSwitcherView() {
        UIViewUtils.remove(viewController: protectionViewConfig.appSwitcher.viewController)
    }
}
