//
//  MMTFacialNerveUtils.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit

extension Double {
    /// Rounds the double to decimal places value
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

extension Date {
    func get(_ components: Calendar.Component..., calendar: Calendar = Calendar.current) -> DateComponents {
        return calendar.dateComponents(Set(components), from: self)
    }
    
    func get(_ component: Calendar.Component, calendar: Calendar = Calendar.current) -> Int {
        return calendar.component(component, from: self)
    }
}

extension UIColor {
    func lighter(componentDelta: CGFloat = 0.1) -> UIColor {
        return  makeColor(componentDelta: componentDelta)
    }
    
    func darker(componentDelta: CGFloat = 0.1) -> UIColor {
        return makeColor(componentDelta: -1 * componentDelta)
    }
    
    // Add value to component ensuring the result is between 0 and 1
    private func add(_ value: CGFloat, toComponent: CGFloat) -> CGFloat {
        return max(0, min(1, toComponent + value))
    }
    
    private func makeColor(componentDelta: CGFloat) -> UIColor {
            var red: CGFloat = 0
            var blue: CGFloat = 0
            var green: CGFloat = 0
            var alpha: CGFloat = 0
            
            // Extract r,g,b,a components from the
            // current UIColor
            getRed(
                &red,
                green: &green,
                blue: &blue,
                alpha: &alpha
            )
            
            // Create a new UIColor modifying each component
            // by componentDelta, making the new UIColor either
            // lighter or darker.
            return UIColor(
                red: add(componentDelta, toComponent: red),
                green: add(componentDelta, toComponent: green),
                blue: add(componentDelta, toComponent: blue),
                alpha: alpha
            )
        }
}
