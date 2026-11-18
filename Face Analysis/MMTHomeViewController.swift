//
//  MMTFacialNerveHomeViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit
import CoreData

class MMTHomeViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate {
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
        self.title = "Face Analysis"
        self.navigationController?.navigationBar.prefersLargeTitles = true
        let receiverButton = UIBarButtonItem(title: "Server", style: .plain, target: self, action: #selector(configureReceiver))
        self.navigationItem.leftBarButtonItem = receiverButton
        let button1 = UIBarButtonItem(title: "Manage Data", style: .plain, target: self, action: #selector(manageData))
        self.navigationItem.rightBarButtonItem  = button1
        
        subjectTextField.delegate = self
        recordingPickerView.delegate = self
        recordingPickerView.dataSource = self
    
        view.addSubview(subjectLabel)
        view.addSubview(subjectTextField)
        view.addSubview(pickerLabel)
        view.addSubview(recordingPickerView)
        view.addSubview(startButton)
        
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
            subjectLabel.topAnchor.constraint(equalTo: guide.topAnchor, constant: 20),
            subjectLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            subjectLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            
            subjectTextField.topAnchor.constraint(equalTo: subjectLabel.bottomAnchor, constant: 8),
            subjectTextField.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            subjectTextField.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            subjectTextField.heightAnchor.constraint(equalToConstant: 40),
            
            pickerLabel.topAnchor.constraint(equalTo: subjectTextField.bottomAnchor, constant: 30),
            pickerLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            pickerLabel.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            
            recordingPickerView.topAnchor.constraint(equalTo: pickerLabel.bottomAnchor, constant: 0),
            recordingPickerView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            recordingPickerView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 20),
            
            startButton.topAnchor.constraint(greaterThanOrEqualTo: recordingPickerView.bottomAnchor, constant: 30),
            startButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -30),
            startButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 30),
            startButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 60),
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - UI-Elements
    
    /*private var resultsButton: MMTButton = {
        let button = MMTButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleText = "See results"
        button.addTarget(self, action: #selector(showDiaryView), for: .touchUpInside)
        button.titleLabel?.font = .systemFont(ofSize: 20)
        return button
    }()*/
    
    /*private var roundIconView: MMTRoundImage = {
        let icon = MMTRoundImage()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(named: "facial nerve")
        return icon
    }()*/
    
    private var subjectLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Subject ID"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = UIColor(named: "FontColor")
        return label
    }()
    
    private var subjectTextField: UITextField = {
        let textField = UITextField()
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.placeholder = "Enter subject ID"
        textField.backgroundColor = UIColor.white
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private var pickerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Recording Type"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = UIColor(named: "FontColor")
        return label
    }()
    
    private var recordingPickerView: UIPickerView = {
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false
        return pickerView
    }()
    
    private var startButton: MMTButton = {
        let button = MMTButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.titleText = "Start recording"
        button.addTarget(self, action: #selector(showTestView), for: .touchUpInside)
        button.titleLabel?.font = .boldSystemFont(ofSize: 20)
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
    
    /// Opens the data managemenet sheet
    @objc private func manageData() {
        let sheetViewController = MMTFacialNerveDataManagementSheetViewController(nibName: nil, bundle: nil)
        navigationController?.present(sheetViewController, animated: true, completion: nil)
    }

    @objc private func configureReceiver() {
        let alert = UIAlertController(title: "Ubuntu WebSocket Receiver",
                                      message: "Enter the Ubuntu server address. Example: ws://192.168.1.20:8000",
                                      preferredStyle: .alert)
        alert.addTextField { field in
            field.placeholder = "ws://192.168.1.20:8000"
            field.text = MMTRealtimeJSONClient.shared.configuredServerURL
            field.keyboardType = .URL
            field.autocapitalizationType = .none
            field.autocorrectionType = .no
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Save & Test", style: .default) { [weak self, weak alert] _ in
            let serverURL = alert?.textFields?.first?.text ?? ""
            do {
                try MMTRealtimeJSONClient.shared.configure(serverURL: serverURL)
                MMTRealtimeJSONClient.shared.testConnection(serverURL: serverURL) { [weak self] result in
                    switch result {
                    case .success:
                        self?.navigationItem.prompt = "Connected to Ubuntu receiver"
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                            self?.navigationItem.prompt = nil
                        }
                    case .failure(let error):
                        let errorAlert = UIAlertController(title: "Could not connect",
                                                           message: error.localizedDescription + " Check the Ubuntu Wi-Fi IP, port 8000, and firewall.",
                                                           preferredStyle: .alert)
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(errorAlert, animated: true)
                    }
                }
            } catch {
                let errorAlert = UIAlertController(title: "Invalid receiver settings",
                                                   message: error.localizedDescription,
                                                   preferredStyle: .alert)
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                DispatchQueue.main.async { [weak self] in
                    self?.present(errorAlert, animated: true)
                }
            }
        })
        present(alert, animated: true)
    }
    
    // Original: push introduction view
    @objc private func showTestView() {
        // Create a new UUID for every recording
        SessionManager.sharedManager.currentSession = UUID()
        
        // Present the test view
        let testView = MMTFacialNerveTestViewController()
        testView.choice = SessionManager.sharedManager.currentRecording.description
        testView.modalPresentationStyle = .fullScreen
        
        present(testView, animated: true)
    }
    
    // MARK: - neuro-tool protocol functions
    
    func showMMTView() -> UIViewController {
        let viewController = MMTHomeViewController()
        return viewController
    }
    
    func getHomeView() -> UIViewController {
        let viewController = MMTHomeViewController()
        return viewController
    }
    
    // MARK: - UITextFieldDelegate
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        guard let id = textField.text else { return }
        SessionManager.sharedManager.subjectID = id
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
      textField.resignFirstResponder()
      return true
    }
    
    // MARK: - PickerView
        
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
     
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return RecordingType.allCases.count
    }
        
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return RecordingType(rawValue: row)?.description
    }
        
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        guard let recordingType = RecordingType(rawValue: row) else { return }
        SessionManager.sharedManager.currentRecording = recordingType
    }
}
