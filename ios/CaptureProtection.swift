import React
import UIKit
import Foundation

struct ProtectionConfig {
    var screenshot: Bool = false
    var screenRecord: Bool = false
    var appSwitcher: Bool = false
}

struct CaptureProtectionConfig {
    var prevent = ProtectionConfig()
    var observer = ProtectionConfig()
}

@objc(CaptureProtection)
class CaptureProtection: RCTEventEmitter {
    private var hasListeners = false
    private var config = CaptureProtectionConfig()
    
    private var secureTextField: UITextField?
    private var protecterViewController: UIViewController?
    private var protecterScreenViewController: UIViewController?
    private var text: String?
    private var textColor: String?
    private var backgroundColor: String?
    private var backgroundScreenColor: String?
    
    // -------------------------------------------------------------------------
    func getPreventStatus() -> Int {
        let result =
        (config.prevent.screenshot ? Constants.CaptureEventType.PREVENT_SCREEN_CAPTURE.rawValue : 0)
        + (config.prevent.screenRecord ? Constants.CaptureEventType.PREVENT_SCREEN_RECORDING.rawValue : 0)
        + (config.prevent.appSwitcher ? Constants.CaptureEventType.PREVENT_SCREEN_APP_SWITCHING.rawValue : 0)
        
        if result == 0 {
            return Constants.CaptureEventType.ALLOW.rawValue
        }
        return result
    }
    // -------------------------------------------------------------------------
    
    
    // -------------------------------------------------------------------------
    override init() {
        super.init()
        addScreenshotObserver()
        addScreenRecordObserver()
        addAppSwitcherObserver()
        addBundleReloadObserver()
    }
    // -------------------------------------------------------------------------
    
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
        self.eventScreenRecordImmediate()
    }
    
    @objc(stopObserving)
    override func stopObserving() {
        hasListeners = false
    }
    
    // ScreenShot
    @objc func allowScreenShot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.secureScreenshotView(isSecure: false)
            self.config.prevent.screenshot = false
            if self.hasListeners {
                self.sendEvent(
                    withName: "CaptureProtectionListener",
                    body: self.getPreventStatus()
                )
            }
            resolver(true)
        }
    }
    
    @objc func preventScreenShot(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.secureScreenshotView(isSecure: true)
            self.config.prevent.screenshot = true
            if self.hasListeners {
                self.sendEvent(
                    withName: "CaptureProtectionListener",
                    body: self.getPreventStatus()
                )
            }
            resolver(true)
        }
    }
    
    // Screen Record
    @objc func allowScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.config.prevent.screenRecord = false
            self.removeRecordProtectionScreen()
            if self.hasListeners {
                self.sendEvent(
                    withName: "CaptureProtectionListener",
                    body: self.getPreventStatus()
                )
            }
            resolver(true)
        }
    }
    
    @objc func preventScreenRecord(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.eventScreenRecordImmediate(true)
            if self.hasListeners {
                self.sendEvent(
                    withName: "CaptureProtectionListener",
                    body: self.getPreventStatus()
                )
            }
            resolver(true)
        }
    }
    
    @objc func preventScreenRecordWithText(_ text: String,
                                           textColor: String,
                                           backgroundColor: String,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.eventScreenRecordImmediate(true)
            resolver(nil)
        }
    }
    
    @objc func preventScreenRecordWithImage(_ image: NSDictionary,
                                            resolver: @escaping RCTPromiseResolveBlock,
                                            rejecter: @escaping RCTPromiseRejectBlock) {
        DispatchQueue.main.async {
            self.eventScreenRecordImmediate(true)
            resolver(nil)
        }
    }
    
    // App Switcher
    @objc func allowAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        config.prevent.appSwitcher = false
        if self.hasListeners {
            self.sendEvent(
                withName: "CaptureProtectionListener",
                body: self.getPreventStatus()
            )
        }
        resolver(nil)
    }
    
    @objc func preventAppSwitcher(_ resolver: @escaping RCTPromiseResolveBlock, rejecter: @escaping RCTPromiseRejectBlock) {
        config.prevent.appSwitcher = true
        if self.hasListeners {
            self.sendEvent(
                withName: "CaptureProtectionListener",
                body: self.getPreventStatus()
            )
        }
        resolver(nil)
    }
    
    @objc func preventAppSwitcherWithText(_ text: String,
                                          textColor: String,
                                          backgroundColor: String,
                                          resolver: @escaping RCTPromiseResolveBlock,
                                          rejecter: @escaping RCTPromiseRejectBlock) {
        resolver(nil)
    }
    
    @objc func preventAppSwitcherWithImage(_ image: NSDictionary,
                                           resolver: @escaping RCTPromiseResolveBlock,
                                           rejecter: @escaping RCTPromiseRejectBlock) {
        resolver(nil)
    }
    
    // Etc
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
    
    // -------------------------------------------------------------------------
    
    // -------------------------------------------------------------------------
    func triggerEvent(_ event: Constants.CaptureEventType) {
        if hasListeners {
            self.sendEvent(
                withName: "CaptureProtectionListener",
                body: event.rawValue
            )
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool,
                   isCaptured == true {
                    self.sendEvent(
                        withName: "CaptureProtectionListener",
                        body: Constants.CaptureEventType.RECORDING.rawValue
                    )
                } else {
                    self.sendEvent(
                        withName: "CaptureProtectionListener",
                        body: Constants.CaptureEventType.UNKNOWN.rawValue
                    )
                }
                
            }
        }
    }
    // -------------------------------------------------------------------------

    // ------------------------------------------------------------------------- 
    @objc func eventScreenshot(notification: Notification) {
        self.triggerEvent(Constants.CaptureEventType.CAPTURED)
    }
    
    @objc func eventScreenRecord(notification: Notification, isEvent: Bool = false) {
        if let isCaptured = UIScreen.main.value(forKey: "isCaptured") as? Bool {
            if isCaptured {
                if config.prevent.screenRecord {
                    createRecordProtectionScreen()
                }
                if hasListeners {
                    self.sendEvent(
                        withName: "CaptureProtectionListener",
                        body: Constants.CaptureEventType.RECORDING.rawValue
                    )
                }
            } else {
                removeRecordProtectionScreen()
                if hasListeners && !isEvent {
                    self.triggerEvent(  Constants.CaptureEventType.END_RECORDING )
                }
            }
        }
    }

    func eventScreenRecordImmediate(_ prevent: Bool = false) {
        if (prevent) {
            self.config.prevent.screenRecord = true
        }
        self.eventScreenRecord(notification: Notification(name: Notification.Name("Init")), isEvent: true)
    }
    // -------------------------------------------------------------------------
    
    // -------------------------------------------------------------------------
    private func addScreenshotObserver() {
        guard !self.config.observer.screenshot else { return }
        self.config.observer.screenshot = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenshot(notification:)), name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func removeScreenShotObserver() {
        guard self.config.observer.screenshot else { return }
        self.config.observer.screenshot = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.userDidTakeScreenshotNotification, object: nil)
    }
    
    private func addScreenRecordObserver() {
        guard !self.config.observer.screenRecord else { return }
        self.config.observer.screenRecord = true
        NotificationCenter.default.addObserver(self, selector: #selector(eventScreenRecord), name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func removeScreenRecordObserver() {
        guard self.config.observer.screenRecord else { return }
        self.config.observer.screenRecord = false
        NotificationCenter.default.removeObserver(self, name: UIScreen.capturedDidChangeNotification, object: nil)
    }
    
    private func addAppSwitcherObserver() {
        guard !self.config.observer.appSwitcher else { return }
        self.config.observer.screenRecord = true
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
    
    private func removeBackgroundObserver() {
        guard self.config.observer.appSwitcher else { return }
        self.config.observer.screenRecord = false
        NotificationCenter.default.removeObserver(self, name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.didBecomeActiveNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    
    private func addBundleReloadObserver() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.RCTBridgeWillReload, object: nil, queue: nil) { [weak self] _ in
            self?.removeScreenShotObserver()
            self?.removeScreenRecordObserver()
            self?.removeBackgroundObserver()
            
            self?.removeRecordProtectionScreen()
            self?.secureScreenshotView(isSecure: false)
            
            if let existingController = self?.protecterScreenViewController {
                existingController.willMove(toParent: nil)
                existingController.view.removeFromSuperview()
                existingController.removeFromParent()
            }
            
            if let existingController = self?.protecterViewController {
                existingController.willMove(toParent: nil)
                existingController.view.removeFromSuperview()
                existingController.removeFromParent()
            }
            self!.config = CaptureProtectionConfig()
            
        }
    }
    
    // -------------------------------------------------------------------------
    

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
    
    private func secureBackgroundView(show: Bool) {
        DispatchQueue.main.async {
            if self.protecterScreenViewController != nil {
                self.protecterScreenViewController?.willMove(toParent: nil)
                self.protecterScreenViewController?.view.removeFromSuperview()
                self.protecterScreenViewController?.removeFromParent()
            }
            
            if !self.config.prevent.appSwitcher {
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
    
    private func secureScreenshotView(isSecure: Bool) {
        DispatchQueue.main.async {
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
    
}
