//
//  UIAlertController+Image.swift
//  Face Analysis
//
//  Created by Lara Marie Reimer on 05.02.23.
//

import Foundation
import UIKit

extension UIAlertController {
    func add(image: UIImage) {
        let maxSize = CGSize(width: 245, height: 300)
        let imageSize = image.size
        
        var ratio: CGFloat
        if imageSize.width >= imageSize.height {
            ratio = maxSize.width / imageSize.width
        } else {
            ratio = maxSize.height / imageSize.height
        }
        
        let scaledSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
        if let resizedImage = image.image(with: scaledSize) {
            var finalResizedImage = resizedImage
            
            if imageSize.height > imageSize.width {
                let left = (maxSize.width - resizedImage.size.width) / 2
                finalResizedImage = resizedImage.withAlignmentRectInsets(UIEdgeInsets(top: 0, left: -left, bottom: 0, right: 0))
            }
            
            let imageAction = UIAlertAction(title: "", style: .default)
            imageAction.isEnabled = false
            imageAction.setValue(finalResizedImage.withRenderingMode(.alwaysOriginal), forKey: "image")
            self.addAction(imageAction)
        }
    }
}
