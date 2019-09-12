//
//  UIColor+SY.swift
//  TorrentAdder
//
//  Created by Stanislas Chevallier on 03/12/2018.
//  Copyright © 2018 Syan. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(light: UIColor, dark: UIColor) {
        if #available(iOS 13.0, *) {
            self.init(dynamicProvider: { $0.userInterfaceStyle == .dark ? dark : light })
        } else {
            self.init(cgColor: light.cgColor)
        }
    }
    
    static var accent: UIColor {
        let light = UIColor(red: 64 / 255, green: 146 / 255, blue: 247 / 255, alpha: 1)
        let dark  = UIColor(red:  0 / 255, green: 106 / 255, blue: 230 / 255, alpha: 1)
        return UIColor(light: light, dark: dark)
    }
    
    static var seeder: UIColor {
        return UIColor(red: 0, green: 0.56, blue: 0.06, alpha: 1)
    }

    static var leechers: UIColor {
        return destructiveAction
    }
    
    static var text: UIColor {
        return UIColor(light: .black, dark: .white)
    }
    
    static var subtext: UIColor {
        return UIColor(light: .darkGray, dark: .darkGray)
    }
    
    static var textOverAccent: UIColor {
        return .white
    }
    
    static var destructiveAction: UIColor {
        return .red
    }
    
    static var basicAction: UIColor {
        return UIColor(light: UIColor(white: 0.85, alpha: 1), dark: .darkGray)
    }
    
    static var background: UIColor {
        return UIColor(light: .white, dark: UIColor(white: 0.05, alpha: 1))
    }
}
