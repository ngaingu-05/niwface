//
//  MMTPercentScoreView.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit

class MMTPercentScoreView: UIView {
    // MARK: - Properties
    
    /// Height and width of the square view
    var size: CGFloat = 100
    var color: UIColor?
    private var didSetupConstraints = false
    
    // MARK: - View Life Cycle
    
    init(size: CGFloat, color: UIColor? = nil) {
        self.size = size
        self.color = color
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        self.setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }
    
    private func setup() {
        self.translatesAutoresizingMaskIntoConstraints = false

        // Setup result segment tracker frame and settings
        if let segmentColor = color {
            resultSegmentTrackerSettings.segmentColor = segmentColor
        }
        resultSegmentTrackerSettings.segmentWidth = (size / 10)
        segment = MMTSegmentIndicator(frame: CGRect(x: 0, y: 0, width: size, height: size))
        segment.settings = resultSegmentTrackerSettings
        
        percentLabel.font = .boldSystemFont(ofSize: (size * 2 / 10))
        
        addSubview(percentLabel)
        addSubview(segment)
    }
    
    override func updateConstraints() {
        if didSetupConstraints == false {
            let guide = self.safeAreaLayoutGuide
            
            let constraints = [
                self.heightAnchor.constraint(equalToConstant: size),
                self.widthAnchor.constraint(equalToConstant: size),
                
                percentLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
                percentLabel.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
                
                segment.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
                segment.centerYAnchor.constraint(equalTo: guide.centerYAnchor)
            ]
            addConstraints(constraints)
        }
        super.updateConstraints()
    }
    
    // MARK: - UI Elements
    
    var segment: MMTSegmentIndicator!
    
    var percentLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(named: "FontColor")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Segment Properties
    
    private var resultSegmentTrackerSettings: MMTSegmentIndicatorSettings = {
        var settings = MMTSegmentIndicatorSettings()
        settings.defaultSegmentColor = UIColor.lightGray
        settings.segmentBorderType = .round
        settings.segmentColor = UIColor.systemBlue
        settings.segmentsCount = 1
        return settings
    }()
}
