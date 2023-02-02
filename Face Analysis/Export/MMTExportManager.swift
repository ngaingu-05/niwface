//
//  MMTExportManager.swift
//  Nerve-ous
//
//  Created by Lara Marie Reimer on 02.02.23.
//

import Foundation

public class ExportManager {
    
    static public let shared = ExportManager()
    
    func exportRecordings(with completion: ((_: Bool) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            // First, get all data from the database.
            let sessionKeyPredicate = NSPredicate(format: "sessionId = %@", SessionManager.sharedManager.currentSession.uuidString)
            
            CoreData.stack.getRecordingsFromStorage(predicate: sessionKeyPredicate) { (recordings) in
                let filename = ExportManager.getDocumentsDirectory().appendingPathComponent(SessionManager.sharedManager.subjectID + "_" + SessionManager.sharedManager.currentRecording.description + "_" + SessionManager.sharedManager.currentSession.uuidString + "_BlendShapeLocations.csv")
                
                var exportString = ExportManager.generateCSVFormatForDataRecording(data: recordings)
                print(exportString)
                
                do {
                    try exportString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                    
                    print(exportString)
                    
                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                    
                } catch {
                    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    func exportAllRecordings(with completion: ((_: Bool) -> Void)?) {
        DispatchQueue.global(qos: .background).async {
            // First, get all data from the database.
            
            CoreData.stack.getRecordingsFromStorage(predicate: nil) { (recordings) in
                let filename = ExportManager.getDocumentsDirectory().appendingPathComponent("FullExport_" + String(Date().timeIntervalSince1970) + "_BlendShapeLocations.csv")
                
                var exportString = ExportManager.generateCSVFormatForDataRecording(data: recordings)
                
                do {
                    try exportString.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
                    
                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                    
                } catch {
                    // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
                    if let completion = completion {
                        DispatchQueue.main.async {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    static func generateCSVFormatForDataRecording(data: [DataRecording]) -> String {
        var csvString = "\("uuid"),\("session"),\("subject"),\("timestamp"),\("expression"),\("browDownLeft"),\("browDownRight"),\("browInnerUp"),\("browOuterUpLeft"),\("browOuterUpRight"),\("cheekPuff"),\("cheekSquintLeft"),\("cheekSquintRight"),\("eyeBlinkLeft"),\("eyeBlinkRight"),\("eyeLookDownLeft"),\("eyeLookDownRight"),\("eyeLookInLeft"),\("eyeLookInRight"),\("eyeLookOutLeft"),\("eyeLookOutRight"),\("eyeLookUpLeft"),\("eyeLookUpRight"),\("eyeSquintLeft"),\("eyeSquintRight"),\("eyeWideLeft"),\("eyeWideRight"),\("jawForward"),\("jawLeft"),\("jawOpen"),\("jawRight"),\("mouthClose"),\("mouthDimpleLeft"),\("mouthDimpleRight"),\("mouthFrownLeft"),\("mouthFrownRight"),\("mouthFunnel"),\("mouthLeft"),\("mouthLowerDownLeft"),\("mouthLowerDownRight"),\("mouthPressLeft"),\("mouthPressRight"),\("mouthPucker"),\("mouthRight"),\("mouthRollLower"),\("mouthRollUpper"),\("mouthShrugLower"),\("mouthShrugUpper"),\("mouthSmileLeft"),\("mouthSmileRight"),\("mouthStretchLeft"),\("mouthStretchRight"),\("mouthUpperUpLeft"),\("mouthUpperUpRight"),\("noseSneerLeft"),\("noseSneerRight"),\("tongueOut")\n"
        
        for record in data {
            csvString = csvString.appending("\(String(describing: record.uuid)),\(record.sessionId),\(String(describing: record.subjectName)),\(String(describing: record.timestamp)),\(String(describing: record.expression)),\(String(describing: record.browDownLeft)),\(String(describing: record.browDownRight)),\(String(describing: record.browInnerUp)),\(String(describing: record.browOuterUpLeft)),\(String(describing: record.browOuterUpRight)),\(String(describing: record.cheekPuff)),\(String(describing: record.cheekSquintLeft)),\(String(describing: record.cheekSquintRight)),\(String(describing: record.eyeBlinkLeft)),\(String(describing: record.eyeBlinkRight)),\(String(describing: record.eyeLookDownLeft)),\(String(describing: record.eyeLookDownRight)),\(String(describing: record.eyeLookInLeft)),\(String(describing: record.eyeLookInRight)),\(String(describing: record.eyeLookOutLeft)),\(String(describing: record.eyeLookOutRight)),\(String(describing: record.eyeLookUpLeft)),\(String(describing: record.eyeLookUpRight)),\(String(describing: record.eyeSquintLeft)),\(String(describing: record.eyeSquintRight)),\(String(describing: record.eyeWideLeft)),\(String(describing: record.eyeWideRight)),\(String(describing: record.jawForward)),\(String(describing: record.jawLeft)),\(String(describing: record.jawOpen)),\(String(describing: record.jawRight)),\(String(describing: record.mouthClose)),\(String(describing: record.mouthDimpleLeft)),\(String(describing: record.mouthDimpleRight)),\(String(describing: record.mouthFrownLeft)),\(String(describing: record.mouthFrownRight)),\(String(describing: record.mouthFunnel)),\(String(describing: record.mouthLeft)),\(String(describing: record.mouthLowerDownLeft)),\(String(describing: record.mouthLowerDownRight)),\(String(describing: record.mouthPressLeft)),\(String(describing: record.mouthPressRight)),\(String(describing: record.mouthPucker)),\(String(describing: record.mouthRight)),\(String(describing: record.mouthRollLower)),\(String(describing: record.mouthRollUpper)),\(String(describing: record.mouthShrugLower)),\(String(describing: record.mouthShrugUpper)),\(String(describing: record.mouthSmileLeft)),\(String(describing: record.mouthSmileRight)),\(String(describing: record.mouthStretchLeft)),\(String(describing: record.mouthStretchRight)),\(String(describing: record.mouthUpperUpLeft)),\(String(describing: record.mouthUpperUpRight)),\(String(describing: record.noseSneerLeft)),\(String(describing: record.noseSneerRight)),\(String(describing: record.tongueOut))\n")
        }
        
        return csvString
    }
    
    static func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
