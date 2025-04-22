//
//  Config.swift
//
//
//  Created by lethe(wn-na, lecheln00@gmail.com) on 4/6/25.
//

import UIKit
import Foundation

public class UIViewUtils {
    public static func imageView(tag: Int, image: UIImage) -> UIViewController  {
        guard let window = UIApplication.shared.delegate?.window ?? nil else { return UIViewController() }
        
        let viewController = UIViewController()
        viewController.view.tag = tag
        
        let imageView = UIImageView(image: image)
        imageView.frame = window.frame
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFit
        
        viewController.view.addSubview(imageView)
        viewController.view.backgroundColor = .white
        
        return viewController
    }
    
    public static func textView(tag: Int, text: String,
                        textColor: String,
                        backgroundColor: String) -> UIViewController {
        guard let window = UIApplication.shared.delegate?.window ?? nil else { return UIViewController()  }
        
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
        guard (UIApplication.shared.delegate?.window ?? nil) != nil else { return UIViewController() }
        
        let viewController = UIViewController()
        viewController.view.tag = tag
        viewController.view.backgroundColor = TextUtils.colorFromHexString(hexString: backgroundColor, defaultColor: .white)
        return viewController
    }

    public static func remove(tag: Int) {
       DispatchQueue.main.async {
           guard let window = UIApplication.shared.delegate?.window else { return }
           if let existingViewController = window?.viewWithTag(tag)?.next as? UIViewController {
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
