//
//  MMTFacialNerveDiaryViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit

// swiftlint:disable type_body_length
class MMTFacialNerveDiaryViewController: UIViewController {
    // MARK: - Properties
    
    private var totalScore = 100.0
    private var weeklyDifference = "-"
    private var monthlyDifference = "-"
        
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter
    }()
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        self.navigationItem.titleView = topTitleLabel
        
        view.addSubview(navBarExtensionView)
        view.addSubview(bottomTitleLabel)
        view.addSubview(dataManagementButton)
        
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
            
            dataManagementButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 10),
            dataManagementButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -10),
            dataManagementButton.topAnchor.constraint(equalTo: guide.bottomAnchor, constant: -100),
            dataManagementButton.heightAnchor.constraint(equalToConstant: 50),
        ]
        NSLayoutConstraint.activate(constraints)
            
        // Populate the view with Data
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
    
    private var dataManagementButton: MMTButton = {
        let button = MMTButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleText = "Manage Test Data"
        button.addTarget(self, action: #selector(manageData), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
        return button
    }()
    
    /// Creates array of averages for each region log key
    private func calculateLogAverages(regionLog: [String: [Double]]) -> [String: Double] {
        var averagesDict: [String: Double] = [:]
        for (key, entry) in regionLog {
            if !entry.isEmpty {
                let entrySum = Double(entry.reduce(0.0, +))
                let entryCount = Double(entry.count)
                averagesDict[key] = ( entrySum / entryCount ).rounded(toPlaces: 1)
            } else {
                continue
            }
        }
        return averagesDict
    }
    
    /// Calculates the weekly and monthy changes in total score
    private func makeTotalScores(totalScoreLog: [Date: Double ]) {
        let weekInterval = TimeInterval(0 - 7 * 24 * 60 * 60)
        let monthInterval = TimeInterval(0 - 30 * 24 * 60 * 60)
        
        var currentTotalDate = Date(timeIntervalSinceReferenceDate: TimeInterval(0))
        var currWeekLogs: [Double] = []
        var currMonthLogs: [Double] = []
        var prevWeekLogs: [Double] = []
        var prevMonthLogs: [Double] = []
        
        for (key, entry) in totalScoreLog {
            if key >= Date(timeIntervalSinceNow: monthInterval) {
                currMonthLogs.append(entry)
                
                if key >= Date(timeIntervalSinceNow: weekInterval) {
                    currWeekLogs.append(entry)
                } else if key >= Date(timeIntervalSinceNow: weekInterval * 2) {
                    prevWeekLogs.append(entry)
                }
            } else if key >= Date(timeIntervalSinceNow: monthInterval * 2) {
                prevMonthLogs.append(entry)
            }
            
            if key >= currentTotalDate {
                totalScore = entry
                currentTotalDate = key
            }
        }
        
        if !currWeekLogs.isEmpty && !prevWeekLogs.isEmpty {
            let currentWeekAvg = currWeekLogs.reduce(0.0, +) / Double(currWeekLogs.count)
            let prevWeekAvg = prevWeekLogs.reduce(0.0, +) / Double(prevWeekLogs.count)
            let diff = (currentWeekAvg - prevWeekAvg).rounded(toPlaces: 1)
            weeklyDifference = (diff > 0 ? "+" : "") + diff.description + "%"
        }
        
        if !currMonthLogs.isEmpty && !prevMonthLogs.isEmpty {
            let currentMonthAvg = currMonthLogs.reduce(0.0, +) / Double(currMonthLogs.count)
            let prevMonthAvg = prevMonthLogs.reduce(0.0, +) / Double(prevMonthLogs.count)
            let diff = (currentMonthAvg - prevMonthAvg).rounded(toPlaces: 1)
            monthlyDifference = (diff > 0 ? "+" : "") + diff.description + "%"
        }
    }
    
    // MARK: - Button action functions
    /// Opens the data managemenet sheet
    @objc private func manageData() {
        let sheetViewController = MMTFacialNerveDataManagementSheetViewController(nibName: nil, bundle: nil)
        navigationController?.present(sheetViewController, animated: true, completion: nil)
    }
    
    // MARK: - neuro-tool protocol functions
    
    func showMMTView() -> UIViewController {
        let viewController = MMTFacialNerveDiaryViewController()
        return viewController
    }
}
