//
//  MMTFacialNerveDataManagementSheetViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import UIKit
import CoreData
import PDFKit

class MMTFacialNerveDataManagementSheetViewController: UIViewController {
    // MARK: - Properties

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if #available(iOS 15.0, *) {
            if let presentationController = presentationController as? UISheetPresentationController {
                presentationController.detents = [
                    .medium()
                ]
            }
        }
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(dismissSelf))
        
        view.backgroundColor = UIColor.white
        view.addSubview(vStack)
        view.addSubview(doneButton)

        vStack.addArrangedSubview(titleLabel)
        vStack.addArrangedSubview(buttonsStack)
        buttonsStack.addArrangedSubview(exportDataButton)
        buttonsStack.addArrangedSubview(deleteDataButton)

        let guide = self.view.safeAreaLayoutGuide

        let constraints = [
            vStack.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -10),
            vStack.topAnchor.constraint(equalTo: guide.topAnchor, constant: 20),
            vStack.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            
            buttonsStack.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -10),
            buttonsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            buttonsStack.centerXAnchor.constraint(equalTo: vStack.centerXAnchor),
            
            exportDataButton.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -10),
            exportDataButton.heightAnchor.constraint(equalToConstant: 50),
            
            deleteDataButton.widthAnchor.constraint(equalTo: guide.widthAnchor, constant: -10),
            deleteDataButton.heightAnchor.constraint(equalToConstant: 50),
            
            doneButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 15),
            doneButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    // MARK: - UI Elements

    private var vStack: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .center
        view.distribution = .equalCentering
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Manage Data"
        label.font = .boldSystemFont(ofSize: 20)
        label.textColor = UIColor(named: "FontColor")
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var buttonsStack: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alignment = .center
        view.distribution = .equalCentering
        view.axis = .vertical
        view.translatesAutoresizingMaskIntoConstraints = false
        view.spacing = 5
        return view
    }()
    
    private var exportDataButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Export Data", for: .normal)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.setImage(UIImage(systemName: "square.and.arrow.down"), for: .normal)
        button.addTarget(self, action: #selector(exportData), for: .touchUpInside)
        button.layer.borderColor = UIColor.systemBlue.cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 0)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        return button
    }()
    
    private var deleteDataButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Delete Data Permanently", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.tintColor = UIColor.white
        button.backgroundColor = UIColor.red
        button.setImage(UIImage(systemName: "trash.fill"), for: .normal)
        button.addTarget(self, action: #selector(confirmAndDeleteData), for: .touchUpInside)
        button.layer.cornerRadius = 10
        button.titleLabel?.textAlignment = .left
        button.contentHorizontalAlignment = .left
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        button.titleEdgeInsets = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)
        return button
    }()
    
    private var doneButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Done", for: .normal)
        button.setTitleColor(UIColor.systemBlue, for: .normal)
        button.addTarget(self, action: #selector(dismissSelf), for: .touchUpInside)
        button.titleLabel?.textAlignment = .right
        return button
    }()
    
    // MARK: Export
    
    /// Expressions which are being done during the test
    /*private let expressions = [
        MMTFacialExpression.smile,
        MMTFacialExpression.raisedEyebrows,
        MMTFacialExpression.puffedCheeks,
        MMTFacialExpression.pursedLips,
        MMTFacialExpression.closedEyes
    ]*/
     
     private let expressions = [
                    "anger",
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
    
    
    @objc func exportData() {
        var items = [URL]()
        
        let data = fetchDataAsTableDataItems()
        
        var dataForCurrentUuid = [DataRecording]()
        var currentUuid = data[0].uuid
        
        for i in 0...data.count - 1 {
            // End of Data?
            if(i == data.count - 1) {
                dataForCurrentUuid.append(data[i])
                
                let csvString = generateCsvFormatForDataRecording(data: dataForCurrentUuid)
                items.append(createCsv(csvStr: csvString, name: "FacialNerveRecording", uuid: data[i].uuid!, expression: ""))
                
                
                dataForCurrentUuid = []
            }
            
            // End of same recording block?
            if (data[i].uuid != currentUuid) {
                currentUuid = data[i].uuid
                
                let csvString = generateCsvFormatForDataRecording(data: dataForCurrentUuid)
                items.append(createCsv(csvStr: csvString, name: "FacialNerveRecording", uuid: data[i].uuid!, expression: ""))
                
                dataForCurrentUuid = []
            }
            
            dataForCurrentUuid.append(data[i])
        }
        
        let ac = UIActivityViewController(activityItems: items, applicationActivities: nil)
        DispatchQueue.main.async {
            self.present(ac, animated: true)
        }
    }
    
    func createCsv(csvStr: String, name: String, uuid: UUID, expression: String) -> URL {
        let fileManager = FileManager.default
        do {
            let path = try fileManager.url(for: .documentDirectory, in: .allDomainsMask, appropriateFor: nil, create: false)
            let fileURL = path.appendingPathComponent("CSV-\(name)-\(uuid.uuidString)-\(expression).csv")
            try csvStr.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("error creating file")
        }
        return URL(fileURLWithPath: "")
    }
    
    func generateCsvFormatForDataRecording(data: [DataRecording]) -> String {
        var csvString = "\("UUID"),\("Subject"),\("Timestamp"),\("Expression"),\("browDownLeft"),\("browDownRight"),\("browInnerUp"),\("browOuterUpLeft"),\("browOuterUpRight"),\("cheekPuff"),\("cheekSquintLeft"),\("cheekSquintRight"),\("eyeBlinkLeft"),\("eyeBlinkRight"),\("eyeLookDownLeft"),\("eyeLookDownRight"),\("eyeLookInLeft"),\("eyeLookInRight"),\("eyeLookOutLeft"),\("eyeLookOutRight"),\("eyeLookUpLeft"),\("eyeLookUpRight"),\("eyeSquintLeft"),\("eyeSquintRight"),\("eyeWideLeft"),\("eyeWideRight"),\("jawForward"),\("jawLeft"),\("jawOpen"),\("jawRight"),\("mouthClose"),\("mouthDimpleLeft"),\("mouthDimpleRight"),\("mouthFrownLeft"),\("mouthFrownRight"),\("mouthFunnel"),\("mouthLeft"),\("mouthLowerDownLeft"),\("mouthLowerDownRight"),\("mouthPressLeft"),\("mouthPressRight"),\("mouthPucker"),\("mouthRight"),\("mouthRollLower"),\("mouthRollUpper"),\("mouthShrugLower"),\("mouthShrugUpper"),\("mouthSmileLeft"),\("mouthSmileRight"),\("mouthStretchLeft"),\("mouthStretchRight"),\("mouthUpperUpLeft"),\("mouthUpperUpRight"),\("noseSneerLeft"),\("noseSneerRight"),\("tongueOut")\n"
        
        for record in data {
            csvString = csvString.appending("\(String(describing: record.uuid!)),\(String(describing: record.subjectName!)),\(String(describing: record.timestamp!)),\(String(describing: record.expression!)),\(String(describing: record.browDownLeft)),\(String(describing: record.browDownRight)),\(String(describing: record.browInnerUp)),\(String(describing: record.browOuterUpLeft)),\(String(describing: record.browOuterUpRight)),\(String(describing: record.cheekPuff)),\(String(describing: record.cheekSquintLeft)),\(String(describing: record.cheekSquintRight)),\(String(describing: record.eyeBlinkLeft)),\(String(describing: record.eyeBlinkRight)),\(String(describing: record.eyeLookDownLeft)),\(String(describing: record.eyeLookDownRight)),\(String(describing: record.eyeLookInLeft)),\(String(describing: record.eyeLookInRight)),\(String(describing: record.eyeLookOutLeft)),\(String(describing: record.eyeLookOutRight)),\(String(describing: record.eyeLookUpLeft)),\(String(describing: record.eyeLookUpRight)),\(String(describing: record.eyeSquintLeft)),\(String(describing: record.eyeSquintRight)),\(String(describing: record.eyeWideLeft)),\(String(describing: record.eyeWideRight)),\(String(describing: record.jawForward)),\(String(describing: record.jawLeft)),\(String(describing: record.jawOpen)),\(String(describing: record.jawRight)),\(String(describing: record.mouthClose)),\(String(describing: record.mouthDimpleLeft)),\(String(describing: record.mouthDimpleRight)),\(String(describing: record.mouthFrownLeft)),\(String(describing: record.mouthFrownRight)),\(String(describing: record.mouthFunnel)),\(String(describing: record.mouthLeft)),\(String(describing: record.mouthLowerDownLeft)),\(String(describing: record.mouthLowerDownRight)),\(String(describing: record.mouthPressLeft)),\(String(describing: record.mouthPressRight)),\(String(describing: record.mouthPucker)),\(String(describing: record.mouthRight)),\(String(describing: record.mouthRollLower)),\(String(describing: record.mouthRollUpper)),\(String(describing: record.mouthShrugLower)),\(String(describing: record.mouthShrugUpper)),\(String(describing: record.mouthSmileLeft)),\(String(describing: record.mouthSmileRight)),\(String(describing: record.mouthStretchLeft)),\(String(describing: record.mouthStretchRight)),\(String(describing: record.mouthUpperUpLeft)),\(String(describing: record.mouthUpperUpRight)),\(String(describing: record.noseSneerLeft)),\(String(describing: record.noseSneerRight)),\(String(describing: record.tongueOut))\n")
        }
        
        return csvString
    }
    
    @objc private func dismissSelf() {
        self.dismiss(animated: true, completion: {})
    }
    
    @objc private func confirmAndDeleteData() {
        // Give the user the option to discard the results
        let alert = UIAlertController(title: "Delete data permanently?",
                                      message: "The data gathered using this app will be deleted forever and can not be restored!",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Cancel",
                                      style: UIAlertAction.Style.default,
                                      handler: { _ in
            self.navigationController?.popViewController(animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Delete",
                                      style: UIAlertAction.Style.destructive,
                                      handler: { _ in
            self.deleteData()
            self.navigationController?.popViewController(animated: true)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Core Data
    
    /// Deletes all the data saved locally for the Facial Nerve tool
    private func deleteData() {
        let context = CoreData.stack.context
        
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataRecording")
        
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        
        do {
            try context.execute(deleteRequest)
            let alert = UIAlertController(title: "Delete Successful", message: nil, preferredStyle: UIAlertController.Style.alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } catch {
            print("Unable to delete data, \(error)")
        }
    }
    
    /// Fetches all the locally saved data for the Facial Nerve tool and transforms it into an array of DataRecordings  to be used during the CSV generation
    private func fetchDataAsTableDataItems() -> [DataRecording] {
        let context = CoreData.stack.context
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "DataRecording")
        let sortUuid = NSSortDescriptor(key: "uuid", ascending: true)
        let sortTimestamp = NSSortDescriptor(key: "timestamp", ascending: true)
        request.sortDescriptors = [sortUuid, sortTimestamp]
        
        guard let dataEntry = try? context.fetch(request) as? [DataRecording] else {
            print("Unable to fetch data.")
            return []
        }
        
        return dataEntry
    }
    
    // MARK: - neuro-tool protocol functions
    
    func showMMTView() -> UIViewController {
        let viewController = MMTFacialNerveDataManagementSheetViewController()
        return viewController
    }
}

struct TableDataItem {
    let date: String
    let totalScore: String
    let foreheadScore: String
    let eyesScore: String
    let mouthScore: String

    init(date: String, totalScore: String, foreheadScore: String, eyesScore: String, mouthScore: String) {
        self.date = date
        self.totalScore = totalScore
        self.foreheadScore = foreheadScore
        self.eyesScore = eyesScore
        self.mouthScore = mouthScore
    }
}
