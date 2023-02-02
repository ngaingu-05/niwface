//
//  MMTNavigationController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit

class MMTNavigationController: UINavigationController {
    var defaultAppearance: UINavigationBarAppearance?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: Customize NavigationBar
        let navigationBarAppearence = UINavigationBarAppearance()
        navigationBarAppearence.shadowColor = .clear
        navigationBarAppearence.backgroundColor = UIColor(named: "BackgroundSecondary")
        navigationBarAppearence.titleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "FontColor") ?? UIColor.black
        ]
        navigationBarAppearence.largeTitleTextAttributes = [
            NSAttributedString.Key.foregroundColor: UIColor(named: "FontColor") ?? UIColor.black
        ]
        navigationBar.standardAppearance = navigationBarAppearence
        navigationBar.scrollEdgeAppearance = navigationBarAppearence
        defaultAppearance = navigationBarAppearence
        navigationBar.prefersLargeTitles = true
        navigationBar.tintColor = UIColor(named: "FontColor") ?? UIColor.black
    }
    
    public func resetToDefaultAppearance() {
        if let defaultAppearance = defaultAppearance {
            navigationBar.standardAppearance = defaultAppearance
            navigationBar.scrollEdgeAppearance = defaultAppearance
        }
    }
}
