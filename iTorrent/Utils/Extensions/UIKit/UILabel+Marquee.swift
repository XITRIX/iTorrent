//
//  UILabel+Marquee.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 23.06.2025.
//

import UIKit

@available(iOS 18.0, *)
extension UILabel {
    var marqueeEnabled: Bool {
        get { value(forKey: "marqueeEnabled") as? Bool ?? false }
        set { setValue(newValue, forKey: "marqueeEnabled") }
    }

    var marqueeRunning: Bool {
        get { value(forKey: "marqueeRunning") as? Bool ?? false }
        set { setValue(newValue, forKey: "marqueeRunning") }
    }

    var marqueeRepeatCount: Int {
        get { value(forKey: "marqueeRepeatCount") as? Int ?? 0 }
        set { setValue(newValue, forKey: "marqueeRepeatCount") }
    }

    var marqueeLoopPadding: Int {
        get { value(forKey: "marqueeLoopPadding") as? Int ?? 0 }
        set { setValue(newValue, forKey: "marqueeLoopPadding") }
    }

    var marqueeUpdatable: Bool {
        get { value(forKey: "marqueeUpdatable") as? Bool ?? true }
        set { setValue(newValue, forKey: "marqueeUpdatable") }
    }

    func enableMarquee() {
        marqueeEnabled = true
        marqueeRunning = true
        marqueeRepeatCount = 0
        marqueeLoopPadding = 40
        marqueeUpdatable = true
    }
}
