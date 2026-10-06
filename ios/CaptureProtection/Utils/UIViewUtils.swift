//
//  Config.swift
//
//
//  Created by lethe(wn-na, lecheln00@gmail.com) on 4/6/25.
//

import UIKit
import Foundation

public class UIViewUtils {
    /// 앱의 메인 윈도우. AppDelegate의 `window`가 없으면(UIScene 기반 앱) 활성 scene의 key window를 쓴다.
    public static func mainWindow() -> UIWindow? {
        if let window = UIApplication.shared.delegate?.window ?? nil {
            return window
        }
        guard let scene = activeWindowScene() else { return nil }
        if let window = (scene.delegate as? UIWindowSceneDelegate)?.window ?? nil {
            return window
        }
        return scene.windows.first(where: { $0.windowLevel == .normal && $0.isKeyWindow })
            ?? scene.windows.first(where: { $0.windowLevel == .normal })
            ?? scene.windows.first(where: { $0.isKeyWindow })
            ?? scene.windows.first
    }

    /// 보호 화면을 올릴 scene. 메인 윈도우의 scene을 우선하고, 없으면 foreground 상태의 scene을 고른다.
    public static func activeWindowScene() -> UIWindowScene? {
        if let scene = (UIApplication.shared.delegate?.window ?? nil)?.windowScene {
            return scene
        }
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.first(where: { $0.activationState == .foregroundActive })
            ?? scenes.first(where: { $0.activationState == .foregroundInactive })
            ?? scenes.first
    }

    /// 현재 앱이 표시되는 화면. UIScene 기반 앱은 scene의 screen, AppDelegate window 기반 앱은 `UIScreen.main`을 쓴다.
    /// scene 조회는 메인 스레드에서만 하고, 그 밖의 스레드에서는 `UIScreen.main`을 쓴다(iPhone에서는 같은 화면이다).
    public static func currentScreen() -> UIScreen {
        guard Thread.isMainThread else { return UIScreen.main }
        return activeWindowScene()?.screen ?? UIScreen.main
    }

    /// 화면 녹화·미러링 여부
    public static func isScreenCaptured() -> Bool? {
        if Thread.isMainThread, #available(iOS 17.0, *), let window = mainWindow() {
            switch window.traitCollection.sceneCaptureState {
            case .active:
                return true
            case .inactive:
                return false
            case .unspecified:
                break
            @unknown default:
                break
            }
        }
        return currentScreen().value(forKey: "isCaptured") as? Bool
    }

    /// 보호 화면용 오버레이 윈도우를 만든다.
    /// UIScene 기반 앱에서는 `windowScene`이 없는 윈도우가 화면에 붙지 않으므로 반드시 scene에 연결한다.
    public static func makeOverlayWindow() -> UIWindow {
        if let scene = activeWindowScene() {
            let window = UIWindow(windowScene: scene)
            window.frame = scene.coordinateSpace.bounds
            return window
        }
        return UIWindow(frame: currentScreen().bounds)
    }

    public static func imageView(tag: Int, image: UIImage, backgroundColor: String, contentMode: UIView.ContentMode) -> UIViewController  {
        guard let window = mainWindow() else { return UIViewController() }
        
        let viewController = UIViewController()
        viewController.view.tag = tag
        
        let imageView = UIImageView(image: image)
        imageView.frame = window.frame
        imageView.clipsToBounds = true
        imageView.contentMode = contentMode
        
        viewController.view.addSubview(imageView)
        viewController.view.backgroundColor = TextUtils.colorFromHexString(hexString: backgroundColor, defaultColor: .white)
        
        return viewController
    }
    
    public static func textView(tag: Int, text: String,
                        textColor: String,
                        backgroundColor: String) -> UIViewController {
        guard let window = mainWindow() else { return UIViewController()  }
        
        let viewController = UIViewController()
        viewController.view.tag = tag
        viewController.view.backgroundColor = TextUtils.colorFromHexString(hexString: backgroundColor, defaultColor: .white)
        
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = TextUtils.colorFromHexString(hexString: textColor)
        label.isUserInteractionEnabled = false
        label.text = text
        label.frame = window.frame
        
        viewController.view.addSubview(label)
        return viewController
    }
    
    public static func view(tag: Int, backgroundColor: String) -> UIViewController {
        guard mainWindow() != nil else { return UIViewController() }
        
        let viewController = UIViewController()
        viewController.view.tag = tag
        viewController.view.backgroundColor = TextUtils.colorFromHexString(hexString: backgroundColor, defaultColor: .white)
        return viewController
    }

    public static func remove(tag: Int) {
       DispatchQueue.main.async {
           guard let window = mainWindow() else { return }
           if let existingViewController = window.viewWithTag(tag)?.next as? UIViewController {
               existingViewController.willMove(toParent: nil)
               existingViewController.view.removeFromSuperview()
               existingViewController.removeFromParent()
           }
       }
   }
    
    public static func remove(viewController: UIViewController?, completion: (() -> Void)? = nil) {
       DispatchQueue.main.async {
           if let existingViewController = viewController {
               existingViewController.willMove(toParent: nil)
               existingViewController.view.removeFromSuperview()
               existingViewController.removeFromParent()
           }
           completion?()
       }
   }
}
