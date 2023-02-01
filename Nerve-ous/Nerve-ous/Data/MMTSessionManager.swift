//
//  MMTSessionManager.swift
//  Nerve-ous
//
//  Created by Lara Marie Reimer on 01.02.23.
//

import Foundation

/**
 *  Class for handling session data.
 **/
class SessionManager {
    static let sharedManager = SessionManager()
    
    var currentSession = UUID()
    var subjectID = ""
    var currentRecording : RecordingType = .eyeBlinkLR
    
    func initSession(id: UUID, subjectID: String, recordingType: RecordingType) {
        self.currentSession = id
        self.subjectID = subjectID
        self.currentRecording = recordingType
    }
    
    func resetSession() {
        currentSession = UUID()
        subjectID = ""
        currentRecording = .eyeBlinkLR
    }
}
