//
//  MMTFacialNerveTestViewController.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import ARKit
import UIKit
import CoreData
import ARVideoKit
import Photos

// swiftlint:disable file_length type_body_length
class MMTFacialNerveTestViewController: UIViewController, ARSessionDelegate, RenderARDelegate, RecordARDelegate {
    // MARK: Properties
    
    /// UI that is hidden during snapshot
    private var uiExcludedInSnapshot: [UIView?] = []
    
    /// Expressions which are being done during the test
    private let expressions = [
        MMTFacialExpression.smile,
        //MMTFacialExpression.raisedEyebrows,
        //MMTFacialExpression.puffedCheeks,
        //MMTFacialExpression.pursedLips,
        //MMTFacialExpression.closedEyes
    ]
    
    public var choice = ""
    
    // Snapshot button size
    private let snapshotButtonSize = 80.0
    
    // ArKit properties
    private var blendShapesTracker: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
    private var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]
    
    //recording properties
    private var recorder: RecordAR?
    private var timedRecordingRunning = false
    private var recordingTimer: Timer? = nil
    private let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    private var recordings = [DataRecording]()
    private var currentFacialExpression = MMTFacialExpression.smile
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        recordingButton.addTarget(self, action: #selector(startTimedRecording), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        
        view.addSubview(sceneView)
        view.addSubview(recordingButton)
        view.addSubview(cancelButton)
        
        
        let guide = self.view.safeAreaLayoutGuide
        let constraints = [
            sceneView.topAnchor.constraint(equalTo: view.topAnchor),
            sceneView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sceneView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sceneView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            recordingButton.widthAnchor.constraint(equalToConstant: snapshotButtonSize),
            recordingButton.heightAnchor.constraint(equalToConstant: snapshotButtonSize),
            recordingButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -10),
            recordingButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            
            cancelButton.widthAnchor.constraint(equalToConstant: 35),
            cancelButton.heightAnchor.constraint(equalToConstant: 35),
            cancelButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 10),
            cancelButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20)
        ]
        NSLayoutConstraint.activate(constraints)
        
        uiExcludedInSnapshot.append(recordingButton)
        uiExcludedInSnapshot.append(cancelButton)
        
        // Initialize ARVideoKit recorder
        
        recorder = RecordAR(ARSceneKit: sceneView)
        
        /*----👇---- ARVideoKit Configuration ----👇----*/
        
        // Set the recorder's delegate
        recorder?.delegate = self
        
        // Set the renderer's delegate
        recorder?.renderAR = self
        
        // Configure the renderer to perform additional image & video processing 👁
        recorder?.onlyRenderWhileRecording = false
        
        // Configure ARKit content mode. Default is .auto
        recorder?.contentMode = .aspectFill
        
        //record or photo add environment light rendering, Default is false
        recorder?.enableAdjustEnvironmentLighting = true
        
        // Set the UIViewController orientations
        recorder?.inputViewOrientations = [.landscapeLeft, .landscapeRight, .portrait]
        // Configure RecordAR to store media files in local app directory
        recorder?.deleteCacheWhenExported = false
        
        recorder?.sessionID = SessionManager.sharedManager.subjectID + "_" + SessionManager.sharedManager.currentRecording.description + "_" + SessionManager.sharedManager.currentSession.uuidString
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Disable dimming during assessment
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARFaceTrackingConfiguration())
        
        // Switch off the orientation lock for UIViewControllers with AR Scenes
        recorder?.rest()
        
        sceneView.session.pause()
    }
    
    // MARK: UI-Elements
    
    private var sceneView: ARSCNView = {
        let arView = ARSCNView()
        arView.translatesAutoresizingMaskIntoConstraints = false
        return arView
    }()
    
    private var recordingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        button.backgroundColor = UIColor.clear
        button.tintColor = UIColor(named: "FontColor")
        button.alpha = 0.8
        return button
    }()
    
    private var cancelButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setBackgroundImage(UIImage(systemName: "multiply.circle.fill"), for: .normal)
        button.backgroundColor = UIColor.clear
        button.tintColor = UIColor(named: "BackgroundPrimary")
        button.alpha = 0.8
        return button
    }()
    
    // MARK: Button action functions
    
    @objc private func startTimedRecording() {
        // Hide the UI
        for element in uiExcludedInSnapshot {
            element?.isHidden = true
        }
        
        // Capture data for 5 seconds
        timedRecordingRunning = true
        currentFacialExpression = expressions[0]
        
        //Record
        if recorder?.status == .readyToRecord {
            recordingQueue.async {
                self.recorder?.record()
            }
        } else if recorder?.status == .recording {
            recorder?.stop() { path in
                self.recorder?.export(video: path)
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [self] in
            self.timedRecordingRunning = false
            
            self.recorder?.stop() { path in
                print(path)
                self.recorder?.export(video: path) { saved, status in
                    print(saved, status)
                    DispatchQueue.main.async {
                        self.exportMessage(success: saved, status: status)
                        
                        // Show the UI
                        for element in self.uiExcludedInSnapshot {
                            element?.isHidden = false
                        }
                        
                        self.finishTest()
                    }
                }
            }
        }
    }
    
    @objc func recordingTimerDidFire(sender: Timer) {
        
    }
    
    @objc private func cancel(sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    // MARK: Exported UIAlert present method
    
    func exportMessage(success: Bool, status: PHAuthorizationStatus) {
        if success {
            print("Media exported to camera roll successfully!")
        }else if status == .denied || status == .restricted || status == .notDetermined {
            let errorView = UIAlertController(title: "😅", message: "Please allow access to the photo library in order to save this media file.", preferredStyle: .alert)
            let settingsBtn = UIAlertAction(title: "Open Settings", style: .cancel) { (_) -> Void in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(URL(string:UIApplication.openSettingsURLString)!)
                    }
                }
            }
            errorView.addAction(UIAlertAction(title: "Later", style: UIAlertAction.Style.default, handler: {
                (UIAlertAction)in
            }))
            errorView.addAction(settingsBtn)
            self.present(errorView, animated: true, completion: nil)
        }else{
            let alert = UIAlertController(title: "Exporting Failed", message: "There was an error while exporting your media file.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    /// Creates a label based on the number of snapshots taken so far
    private func makeLabel(forInstructionStep step: Int) -> String {
        return expressions[step]
            .makeInstructions(forIteration: step)
    }
    
    /// Stores the results
    private func finishTest() {
        CoreData.stack.saveContext()
        
        // Trigger a full export
        ExportManager.shared.exportRecordings { success in
            // Reset the session ID.
            let optionSheet = UIAlertController(title: "Data successfully exported", message: "", preferredStyle: .alert)
            
            let info = UIAlertAction(title: "Okay! Quit this session.", style: .default, handler: { _ in
                // Go back to initial screen
                self.dismiss(animated: true, completion: nil)
            })
            optionSheet.addAction(info)
            self.present(optionSheet, animated: true, completion: nil)
        }
    }
    
    // MARK: ARSessionDelegate
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    // ARFaceTrackingSetup
    func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        if #available(iOS 13.0, *) {
            configuration.maximumNumberOfTrackedFaces = ARFaceTrackingConfiguration.supportedNumberOfTrackedFaces
        }
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Prepare the recorder with sessions configuration
        recorder?.prepare(configuration)
        
        faceAnchorsAndContentControllers.removeAll()
    }
    
    // MARK: Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // Auto-hide the home indicator to maximize immersion in AR experiences.
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    // Hide the status bar to maximize immersion in AR experiences.
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: neuro-tool Protocols
    
    func showMMTView() -> UIViewController {
        let viewController = MMTFacialNerveTestViewController()
        return viewController
    }
    
    // MARK: ARVideoKit Delegate Methods
    
    func frame(didRender buffer: CVPixelBuffer, with time: CMTime, using rawBuffer: CVPixelBuffer) {
        // Do some image/video processing.
    }
    
    func recorder(didEndRecording path: URL, with noError: Bool) {
        if noError {
            // Do something with the video path.
        }
    }
    
    func recorder(didFailRecording error: Error?, and status: String) {
        // Inform user an error occurred while recording.
    }
    
    func recorder(willEnterBackground status: RecordARStatus) {
        // Use this method to pause or stop video recording. Check [applicationWillResignActive(_:)](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1622950-applicationwillresignactive) for more information.
    }
}

extension MMTFacialNerveTestViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        DispatchQueue.main.async {
            let contentController = MMTTexturedFace()
            if node.childNodes.isEmpty, let contentNode = contentController.renderer(renderer, nodeFor: faceAnchor) {
                node.addChildNode(contentNode)
                self.faceAnchorsAndContentControllers[faceAnchor] = contentController
            }
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor,
              let contentController = faceAnchorsAndContentControllers[faceAnchor],
              let contentNode = contentController.contentNode else { return }
        
        if timedRecordingRunning {
            print("recording running")
            contentNode.isHidden = true
            
            let newRecording = DataRecording(context: CoreData.stack.context)
            newRecording.uuid = UUID()
            newRecording.sessionId = SessionManager.sharedManager.currentSession
            newRecording.subjectName = SessionManager.sharedManager.subjectID
            newRecording.timestamp = Date()
            newRecording.expression = choice //self.currentFacialExpression.getString()
            newRecording.browDownLeft = faceAnchor.blendShapes[.browDownLeft] as! Float
            newRecording.browDownRight = faceAnchor.blendShapes[.browDownRight] as! Float
            newRecording.browInnerUp = faceAnchor.blendShapes[.browInnerUp] as! Float
            newRecording.browOuterUpLeft = faceAnchor.blendShapes[.browOuterUpLeft] as! Float
            newRecording.browOuterUpRight = faceAnchor.blendShapes[.browOuterUpRight] as! Float
            newRecording.cheekPuff = faceAnchor.blendShapes[.cheekPuff] as! Float
            newRecording.cheekSquintLeft = faceAnchor.blendShapes[.cheekSquintLeft] as! Float
            newRecording.cheekSquintRight = faceAnchor.blendShapes[.cheekSquintRight] as! Float
            newRecording.eyeBlinkLeft = faceAnchor.blendShapes[.eyeBlinkLeft] as! Float
            newRecording.eyeBlinkRight = faceAnchor.blendShapes[.eyeBlinkRight] as! Float
            newRecording.eyeLookDownLeft = faceAnchor.blendShapes[.eyeLookDownLeft] as! Float
            newRecording.eyeLookDownRight = faceAnchor.blendShapes[.eyeLookDownRight] as! Float
            newRecording.eyeLookInLeft = faceAnchor.blendShapes[.eyeLookInLeft] as! Float
            newRecording.eyeLookInRight = faceAnchor.blendShapes[.eyeLookInRight] as! Float
            newRecording.eyeLookOutLeft = faceAnchor.blendShapes[.eyeLookOutLeft] as! Float
            newRecording.eyeLookOutRight = faceAnchor.blendShapes[.eyeLookOutRight] as! Float
            newRecording.eyeLookUpLeft = faceAnchor.blendShapes[.eyeLookUpLeft] as! Float
            newRecording.eyeLookUpRight = faceAnchor.blendShapes[.eyeLookUpRight] as! Float
            newRecording.eyeSquintLeft = faceAnchor.blendShapes[.eyeSquintLeft] as! Float
            newRecording.eyeSquintRight = faceAnchor.blendShapes[.eyeSquintRight] as! Float
            newRecording.eyeWideLeft = faceAnchor.blendShapes[.eyeWideLeft] as! Float
            newRecording.eyeWideRight = faceAnchor.blendShapes[.eyeWideRight] as! Float
            newRecording.jawForward = faceAnchor.blendShapes[.jawForward] as! Float
            newRecording.jawLeft = faceAnchor.blendShapes[.jawLeft] as! Float
            newRecording.jawOpen = faceAnchor.blendShapes[.jawOpen] as! Float
            newRecording.jawRight = faceAnchor.blendShapes[.jawRight] as! Float
            newRecording.mouthClose = faceAnchor.blendShapes[.mouthClose] as! Float
            newRecording.mouthDimpleLeft = faceAnchor.blendShapes[.mouthDimpleLeft] as! Float
            newRecording.mouthDimpleRight = faceAnchor.blendShapes[.mouthDimpleRight] as! Float
            newRecording.mouthFrownLeft = faceAnchor.blendShapes[.mouthFrownLeft] as! Float
            newRecording.mouthFrownRight = faceAnchor.blendShapes[.mouthFrownRight] as! Float
            newRecording.mouthFunnel = faceAnchor.blendShapes[.mouthFunnel] as! Float
            newRecording.mouthLeft = faceAnchor.blendShapes[.mouthLeft] as! Float
            newRecording.mouthLowerDownLeft = faceAnchor.blendShapes[.mouthLowerDownLeft] as! Float
            newRecording.mouthLowerDownRight = faceAnchor.blendShapes[.mouthLowerDownRight] as! Float
            newRecording.mouthPressLeft = faceAnchor.blendShapes[.mouthPressLeft] as! Float
            newRecording.mouthPressRight = faceAnchor.blendShapes[.mouthPressRight] as! Float
            newRecording.mouthPucker = faceAnchor.blendShapes[.mouthPucker] as! Float
            newRecording.mouthRight = faceAnchor.blendShapes[.mouthRight] as! Float
            newRecording.mouthRollLower = faceAnchor.blendShapes[.mouthRollLower] as! Float
            newRecording.mouthRollUpper = faceAnchor.blendShapes[.mouthRollUpper] as! Float
            newRecording.mouthShrugLower = faceAnchor.blendShapes[.mouthShrugLower] as! Float
            newRecording.mouthShrugUpper = faceAnchor.blendShapes[.mouthShrugUpper] as! Float
            newRecording.mouthSmileLeft = faceAnchor.blendShapes[.mouthSmileLeft] as! Float
            newRecording.mouthSmileRight = faceAnchor.blendShapes[.mouthSmileRight] as! Float
            newRecording.mouthStretchLeft = faceAnchor.blendShapes[.mouthStretchLeft] as! Float
            newRecording.mouthStretchRight = faceAnchor.blendShapes[.mouthStretchRight] as! Float
            newRecording.mouthUpperUpLeft = faceAnchor.blendShapes[.mouthUpperUpLeft] as! Float
            newRecording.mouthUpperUpRight = faceAnchor.blendShapes[.mouthUpperUpRight] as! Float
            newRecording.noseSneerLeft = faceAnchor.blendShapes[.noseSneerLeft] as! Float
            newRecording.noseSneerRight = faceAnchor.blendShapes[.noseSneerRight] as! Float
            newRecording.tongueOut = faceAnchor.blendShapes[.tongueOut] as! Float
            newRecording.anger = 0.0
            newRecording.contempt = 0.0
            newRecording.fear = 0.0
            newRecording.sadness = 0.0
            newRecording.disgust = 0.0
            newRecording.surprise = 0.0
            newRecording.joy = 0.0
            
            self.recordings.append(newRecording)
            CoreData.stack.saveContext()
        } else {
            print("***")
            contentNode.isHidden = false
        }
        
        contentController.renderer(renderer, didUpdate: contentNode, for: anchor)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        faceAnchorsAndContentControllers[faceAnchor] = nil
    }
}
