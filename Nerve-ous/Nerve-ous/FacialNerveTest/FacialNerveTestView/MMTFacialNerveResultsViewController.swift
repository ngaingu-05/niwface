//
//  MMTFacialNerveResultsViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import CoreData
import UIKit

class MMTFacialNerveResultsViewController: UIViewController {
    // MARK: - Properties
    /// The scores from the Facial Nerve test
    private var scores: (total: Double, perRegion: [MMTRegion: Double])
    /// Tracks if the results have been saved yet
    private var resultsSaved = false
    
    init(scores: (total: Double, perRegion: [MMTRegion: Double])) {
        self.scores = scores
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        self.navigationItem.titleView = topTitleLabel

        view.addSubview(navBarExtensionView)
        view.addSubview(bottomTitleLabel)
        view.addSubview(vStackContailer)
        
        vStack.addArrangedSubview(resultInfoLabel)
        addPercentSegmentTrackersToStack()
        vStackContailer.addSubview(vStack)

        let guide = self.view.safeAreaLayoutGuide
        
        let constraints = [
            navBarExtensionView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            navBarExtensionView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            navBarExtensionView.topAnchor.constraint(equalTo: guide.topAnchor),
            navBarExtensionView.heightAnchor.constraint(equalToConstant: 60),
            
            bottomTitleLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            bottomTitleLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            bottomTitleLabel.topAnchor.constraint(equalTo: guide.topAnchor),
            bottomTitleLabel.heightAnchor.constraint(equalToConstant: 50),
            
            vStackContailer.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            vStackContailer.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            vStackContailer.topAnchor.constraint(equalTo: navBarExtensionView.bottomAnchor, constant: 10),
            vStackContailer.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -10),
            
            vStack.trailingAnchor.constraint(equalTo: vStackContailer.trailingAnchor),
            vStack.leadingAnchor.constraint(equalTo: vStackContailer.leadingAnchor),
            vStack.centerYAnchor.constraint(equalTo: vStackContailer.centerYAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: UI-Elements
    
    private var topTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Facial Nerve"
        label.font = .systemFont(ofSize: 22)
        label.textColor = UIColor(named: "FontColor")
        label.textAlignment = .left
        return label
    }()

    private var bottomTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Test Results"
        label.font = .boldSystemFont(ofSize: 30)
        label.textColor = UIColor(named: "FontColor")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var navBarExtensionView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(named: "BackgroundSecondary")
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var percentView: MMTPercentScoreView = {
        let view = MMTPercentScoreView(size: 200)
        return view
    }()
    
    private var vStackContailer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var vStack: UIStackView = {
        let view = UIStackView()
        view.alignment = .center
        view.distribution = .equalCentering
        view.axis = .vertical
        view.spacing = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var hStack: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .center
        view.distribution = .equalCentering
        view.axis = .horizontal
        view.spacing = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var resultInfoLabel: UILabel = {
        var label = UILabel()
        label.font = .boldSystemFont(ofSize: 25)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.textColor = UIColor(named: "FontColor")
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Estimated\n facial nerve function:"
        return label
    }()
    
    // MARK: - Helper Functions
    
    private func addPercentSegmentTrackersToStack() {
        percentView.segment.updateProgress(percent: scores.total)
        percentView.percentLabel.text = (scores.total).rounded(toPlaces: 1).description + "%"
        vStack.addArrangedSubview(percentView)

        let dataColors = [
            UIColor.cyan,
            UIColor.magenta,
            UIColor.yellow
        ]
        
        for (key, element) in scores.perRegion {
            let miniVStack = UIStackView()
            miniVStack.alignment = .center
            miniVStack.distribution = .equalCentering
            miniVStack.axis = .vertical
            miniVStack.translatesAutoresizingMaskIntoConstraints = false
            
            let regionColor = dataColors[hStack.arrangedSubviews.count % dataColors.count]
            
            let regionView = MMTPercentScoreView(size: 80, color: regionColor)
            regionView.segment.updateProgress(percent: element)
            regionView.percentLabel.text = (element).rounded(toPlaces: 1).description + "%"
            
            let regionLabel = UILabel()
            regionLabel.text = key.getLabel()
            regionLabel.textColor = regionColor.darker()
            regionLabel.font = .boldSystemFont(ofSize: 15)
            
            miniVStack.addArrangedSubview(regionView)
            miniVStack.addArrangedSubview(regionLabel)
            
            hStack.addArrangedSubview(miniVStack)
        }
        vStack.addArrangedSubview(hStack)
    }
}
