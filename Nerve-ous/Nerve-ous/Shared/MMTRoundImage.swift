//
//  MMTRoundImage.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit

class MMTRoundImage: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.layer.cornerRadius = self.frame.size.height / 2
        self.clipsToBounds = true
        self.layer.borderColor = UIColor(named: "BackgroundSecondary")?.cgColor
        self.layer.borderWidth = 10
    }
}
