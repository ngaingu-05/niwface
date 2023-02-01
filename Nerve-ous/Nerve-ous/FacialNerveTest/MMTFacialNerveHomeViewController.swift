//
//  MMTFacialNerveHomeViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit
import CoreData

class MMTFacialNerveHomeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    // MARK: - View Controller Life Cycle
    
    var first: Bool
    
    init(first: Bool) {
        self.first = first
        super.init(nibName:nil, bundle:nil)
    }
    
    init() {
        self.first = false
        super.self.init(nibName:nil, bundle:nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        self.title = "Facial Analysis"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        let button1 = UIBarButtonItem(title: "Change Subject", style: .plain, target: self, action: #selector(changeSubject))
        self.navigationItem.rightBarButtonItem  = button1
    
        view.addSubview(roundIconView)
        view.addSubview(resultsButton)
        view.addSubview(startButton)
        view.addSubview(descriptionView)
        
        if (first) {
            let alert = UIAlertController(title: "Terms of use",
                                          message: "I agree that my data will be used for research purposes. These include photos and other personal data.",
                                          preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
                print("Great! Let's start.")}))
            
            self.present(alert, animated: true)
        }
        
        let guide = self.view.safeAreaLayoutGuide
        
        let constraints = [
            resultsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -100),
            resultsButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 100),
            resultsButton.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -10),
            resultsButton.heightAnchor.constraint(equalToConstant: 50),
            
            startButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -30),
            startButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 30),
            startButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 80),
            
            roundIconView.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            roundIconView.topAnchor.constraint(equalTo: guide.topAnchor, constant: 80),
            roundIconView.heightAnchor.constraint(equalToConstant: 200),
            roundIconView.widthAnchor.constraint(equalToConstant: 200),
            
            descriptionView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -30),
            descriptionView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 30),
            descriptionView.topAnchor.constraint(equalTo: roundIconView.bottomAnchor, constant: 20),
            descriptionView.heightAnchor.constraint(equalToConstant: 80)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - UI-Elements
    
    private var resultsButton: MMTButton = {
        let button = MMTButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleText = "See results"
        button.addTarget(self, action: #selector(showDiaryView), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        return button
    }()
    
    private var roundIconView: MMTRoundImage = {
        let icon = MMTRoundImage()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(named: "facial nerve")
        return icon
    }()
    
    private var startButton: MMTButton = {
        let button = MMTButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleText = "Start test"
        button.addTarget(self, action: #selector(showTestView), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 30)
        return button
    }()
    
    private var descriptionView: UITextView = {
        let view = UITextView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .black
        view.text = "Analyze for facial asymmetry, which is an indicator for facial nerve function."
        view.backgroundColor = UIColor(named: "BackgroundPrimary")
        view.font = .systemFont(ofSize: 20)
        view.textAlignment = .justified
        return view
    }()
    
    
    // MARK: - Button action functions
    
    @objc private func changeSubject() {
        let alert = UIAlertController(title: "New subject's name:", message: "Enter a text", preferredStyle: .alert)

        alert.addTextField { (textField) in
            textField.text = "Some default text"
        }

        alert.addAction(UIAlertAction(title: "Save", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            CoreData.subject.name = textField!.text
        }))

        self.present(alert, animated: true, completion: nil)
    }
    
    @objc private func showDiaryView() {
        navigationController?.pushViewController(MMTFacialNerveDiaryViewController(), animated: true)
    }
    
    var choices = ["anger",
                   "fear",
                   "disgust",
                   "joy",
                   "sadness",
                   "surprise",
                   "contempt",
                   "eyeBlinkLR",
                   "eyeLookDownLR",
                   "eyeLookRight",
                   "eyeLookLeft",
                   "eyeLookUpLR",
                   "eyeSquintLR",
                   "eyeWideLR",
                   "jawForward",
                   "jawLeft",
                   "jawRight",
                   "jawOpen",
                   "mouthClose",
                   "mouthFunnel",
                   "mouthPucker",
                   "mouthLeft",
                   "mouthRight",
                   "mouthSmileLR",
                   "mouthFrownLR",
                   "mouthDimpleLR",
                   "mouthStretchLR",
                   "mouthRollLower",
                   "mouthRollUpper",
                   "mouthShrugLower",
                   "mouthShrugUpper",
                   "mouthPressLR",
                   "mouthLowerDownLR",
                   "mouthUpperUpLR",
                   "browDownLR",
                   "browInnerUp",
                   "browOuterUpLeft",
                   "browOuterUpRight",
                   "cheekPuff",
                   "cheekSquintLR",
                   "noseSneerLeft",
                   "noseSneerRight",
                   "tongueOut"]
    var pickerView = UIPickerView()
    var typeValue = String()
    
    //Original: push introduction view
    @objc private func showTestView() {
        let alert = UIAlertController(title: "BlendShapes", message: "\n\n\n\n\n\n\n", preferredStyle: .alert)
                let pickerFrame = UIPickerView(frame: CGRect(x: 5, y: 20, width: 250, height: 140))
                
                alert.view.addSubview(pickerFrame)
                pickerFrame.dataSource = self
                pickerFrame.delegate = self
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (UIAlertAction) in
                    
                    let testView = MMTFacialNerveTestViewController()
                    testView.choice = self.typeValue
                    
                    self.navigationController?.pushViewController(testView, animated: true)
                
                }))
                self.present(alert,animated: true, completion: nil )
    }
    
    // MARK: - neuro-tool protocol functions
    
    func showMMTView() -> UIViewController {
        let viewController = MMTFacialNerveHomeViewController()
        return viewController
    }
    
    func getHomeView() -> UIViewController {
        let viewController = MMTFacialNerveHomeViewController()
        return viewController
    }
    
    func getDiaryView() -> UIViewController {
        let viewController = MMTFacialNerveDiaryViewController()
        return viewController
    }
    
    //MARK - PickerView
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
     
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return choices.count
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return choices[row]
    }
        
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            typeValue = "anger"
        } else if row == 1 {
            typeValue = "fear"
        } else if row == 2 {
            typeValue = "disgust"
        } else if row == 3 {
            typeValue = "joy"
        } else if row == 4 {
            typeValue = "sadness"
        } else if row == 5 {
            typeValue = "surprise"
        } else if row == 6 {
            typeValue = "contempt"
        } else if row == 7 {
            typeValue = "eyeBlinkLR"
        } else if row == 8 {
            typeValue = "eyeLookDownLR"
        } else if row == 9 {
            typeValue = "eyeLookRight"
        } else if row == 10 {
            typeValue = "eyeLookLeft"
        } else if row == 11 {
            typeValue = "eyeLookUpLR"
        } else if row == 12 {
            typeValue = "eyeSquintLR"
        } else if row == 13 {
            typeValue = "eyeWideLR"
        } else if row == 14 {
            typeValue = "jawForward"
        } else if row == 15 {
            typeValue = "jawLeft"
        } else if row == 16 {
            typeValue = "jawRight"
        } else if row == 17 {
            typeValue = "jawOpen"
        } else if row == 18 {
            typeValue = "mouthClose"
        } else if row == 19 {
            typeValue = "mouthFunnel"
        } else if row == 20 {
            typeValue = "mouthPucker"
        } else if row == 21 {
            typeValue = "mouthLeft"
        } else if row == 22 {
            typeValue = "mouthRight"
        } else if row == 23 {
            typeValue = "mouthSmileLR"
        } else if row == 24 {
            typeValue = "mouthFrownLR"
        } else if row == 25 {
            typeValue = "mouthDimpleLR"
        } else if row == 26 {
            typeValue = "mouthStretchLR"
        } else if row == 27 {
            typeValue = "mouthRollLower"
        } else if row == 28 {
            typeValue = "mouthRollUpper"
        } else if row == 29 {
            typeValue = "mouthShrugLower"
        } else if row == 30 {
            typeValue = "mouthShrugUpper"
        } else if row == 31 {
            typeValue = "mouthPressLR"
        } else if row == 32 {
            typeValue = "mouthLowerDownLR"
        } else if row == 33 {
            typeValue = "mouthUpperUpLR"
        } else if row == 34 {
            typeValue = "browDownLR"
        } else if row == 35 {
            typeValue = "browInnerUp"
        } else if row == 36 {
            typeValue = "browOuterUpLeft"
        } else if row == 37 {
            typeValue = "browOuterUpRight"
        } else if row == 38 {
            typeValue = "cheekPuff"
        } else if row == 39 {
            typeValue = "cheekSquintLR"
        } else if row == 40 {
            typeValue = "noseSneerLeft"
        } else if row == 41 {
            typeValue = "noseSneerRight"
        } else if row == 42 {
            typeValue = "tongueOut"
        }
    }
}
