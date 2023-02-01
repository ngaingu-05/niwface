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
    
    // Examination instruction properties
    /// Current step of the test
    private var instructionStep: Int = 0
    /// Expressions which are being done during the test
    //Nur eine Runde drehen; uncomment to record all after one another in one session
    private let expressions = [
        MMTFacialExpression.smile,
        //MMTFacialExpression.raisedEyebrows,
        //MMTFacialExpression.puffedCheeks,
        //MMTFacialExpression.pursedLips,
        //MMTFacialExpression.closedEyes
    ]
    
    public var choice = ""
    
    // Segment properties
    private var segmentUpdatePercentage: Double = 0
    
    // Snapshot button size
    private let snapshotButtonSize = 80.0
    
    // ArKit properties
    private var blendShapesTracker: [ARFaceAnchor.BlendShapeLocation: NSNumber] = [:]
    private var faceAnchorsAndContentControllers: [ARFaceAnchor: VirtualContentController] = [:]
    
    //recording properties
    private var recorder: RecordAR?
    private var timedRecordingRunning = false
    private let recordingQueue = DispatchQueue(label: "recordingThread", attributes: .concurrent)
    private var recordings = [DataRecording]()
    private var currentFacialExpression = MMTFacialExpression.smile
    private var currentTestUuid = UUID()
    
    // MARK: View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Hide navigation controls
        self.tabBarController?.tabBar.isHidden = true
        let navigationBarAppearence = UINavigationBarAppearance()
        navigationBarAppearence.configureWithTransparentBackground()
        self.navigationController?.navigationBar.standardAppearance = navigationBarAppearence
        self.navigationController?.navigationBar.scrollEdgeAppearance = navigationBarAppearence
        
        view.addSubview(sceneView)
        view.addSubview(segmentTrackerView)
        
        segment = MMTSegmentIndicator(frame: CGRect(x: 0,
                                                    y: 0,
                                                    width: snapshotButtonSize + 20,
                                                    height: snapshotButtonSize + 20))
        
        segmentTrackerView.addSubview(segment)
        view.addSubview(recordingButton)

                
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
            
            segmentTrackerView.centerXAnchor.constraint(equalTo: recordingButton.centerXAnchor),
            segmentTrackerView.centerYAnchor.constraint(equalTo: recordingButton.centerYAnchor),
            segmentTrackerView.heightAnchor.constraint(equalTo: recordingButton.heightAnchor, constant: 20),
            segmentTrackerView.widthAnchor.constraint(equalTo: recordingButton.widthAnchor, constant: 20),
            
            segment.topAnchor.constraint(equalTo: segmentTrackerView.topAnchor),
            segment.bottomAnchor.constraint(equalTo: segmentTrackerView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
        
        setupSegmentView()
        
        uiExcludedInSnapshot.append(recordingButton)
        uiExcludedInSnapshot.append(segmentTrackerView)
        
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Disable dimming during assessment
        UIApplication.shared.isIdleTimerDisabled = true
        
        // "Reset" to run the AR session for the first time.
        resetTracking()
        
        //reset Uuid
        currentTestUuid = UUID()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        // Show the hidden navigation UI
        self.tabBarController?.tabBar.isHidden = false
        (self.navigationController as? MMTNavigationController)?.resetToDefaultAppearance()
        
        recorder?.onlyRenderWhileRecording = true
        recorder?.prepare(ARFaceTrackingConfiguration())
        
        // Switch off the orientation lock for UIViewControllers with AR Scenes
        recorder?.rest()
    }
    
    // MARK: UI-Elements
    
    private var sceneView: ARSCNView = {
        let arView = ARSCNView()
        arView.translatesAutoresizingMaskIntoConstraints = false
        return arView
    }()
    
    private var segmentTrackerView: UIView = {
        let segmentView = UIView()
        segmentView.translatesAutoresizingMaskIntoConstraints = false
        return segmentView
    }()
    
    private var segment: MMTSegmentIndicator!
    
    private var recordingButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(startTimedRecording), for: .touchUpInside)
        button.setBackgroundImage(UIImage(systemName: "camera.circle.fill"), for: .normal)
        button.backgroundColor = UIColor.clear
        button.tintColor = UIColor.systemBlue
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
        currentFacialExpression = expressions[instructionStep]
        
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
                self.recorder?.export(video: path) { saved, status in
                    DispatchQueue.main.sync {
                        self.exportMessage(success: saved, status: status)
                        
                        // Show the UI
                        for element in self.uiExcludedInSnapshot {
                            element?.isHidden = false
                        }
                        
                        self.instructionStep += 1
                        self.segment.updateProgress(percent: self.segmentUpdatePercentage * Double(self.instructionStep))
                        
                        // Check if test is completed
                        if self.instructionStep == (self.expressions.count) {
                            self.finishTest()
                        } else {
                            // Move to next instructions step
                            
                        }
                    }
                }
            }
        }
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
/*
    // MARK: Algorithm Functions

    /// Returns a tuple containing the final score and an array of  scores for each individual region
    //TODO: Calculate scores correctly
    private func calculateDigitalFaceIndex() -> (total: Double, perRegion: [MMTRegion: Double]) {
        //newRecording.uuid = currentTestUuid
        //newRecording.timestamp = Date()
        //newRecording.expression = self.currentFacialExpression.getString()
        //recordings
        
        //für jede facial expression dfi ausrechnen und speichern
        for expression in expressions {
            var dfi = 0.0
            
            //für jede region das delta ausrechnen
            let regionMultipliers = [0.1, 0.4, 0.5]
            for i in 0...2 {
                let maxR = findMaxValueForRegionOnSide(region: i, rightSide: true, expression: expression)
                let maxL = findMaxValueForRegionOnSide(region: i, rightSide: false, expression: expression)
                
                let fc = maxR > maxL ? 100.0/maxR : 100.0/maxL
                
                let rRel = maxR * fc
                let lRel = maxL * fc
                
                let delta = maxR > maxL ? rRel - lRel : lRel - rRel
                
                dfi += delta * regionMultipliers[i]
            }
            var realDfi = 1 - dfi
            
            //dfi für die expression speichern -> ein einziges core data objekt für alle werte einer uuid!
        }
        
        //durchschnitts dfi ausrechnen und speichern
        
        
        
        //return (total: 100.0 - (totalScoreSum / Double(expressions.count)), perRegion: totalScoreForRegion)
    }

    // MARK: Helper Functions
    
    /*
     The so-called blend shape coefficients, which describe the movement of the eyebrows, closure of the eyelids, and upward movement of the corners of the mouth are saved as an array.
     --> für alle blendshapes in einer region wir das maximum von einer gesucht
     */
    private func findMaxValueForRegionOnSide(region: Int, rightSide: Bool, expression: MMTFacialExpression) -> Double {
        var relevantRecordings = [DataRecording]()
        for recording in recordings {
            print(recording.uuid!)
            print(currentTestUuid)
            print(recording.expression!)
            print(expression.getString())
            if (recording.uuid == currentTestUuid) && (recording.expression == expression.getString()) {
                relevantRecordings.append(recording)
            }
        }
        
        var relevantValues = [Float]()
        
        switch region {
        //forehead
        case 0:
            //für die region und seite die relevanten werte raussuchen
            if rightSide {
                for recording in relevantRecordings {
                    relevantValues.append(recording.browDownRight)
                    relevantValues.append(recording.browOuterUpRight)
                }
            } else {
                for recording in relevantRecordings {
                    relevantValues.append(recording.browDownLeft)
                    relevantValues.append(recording.browOuterUpLeft)
                }
            }
            break
        //eyes
        case 1:
            //für die region und seite die relevanten werte raussuchen
            if rightSide {
                for recording in relevantRecordings {
                    relevantValues.append(recording.eyeWideRight)
                    relevantValues.append(recording.eyeSquintRight)
                    relevantValues.append(recording.eyeBlinkRight)
                    relevantValues.append(recording.eyeLookUpRight)
                    relevantValues.append(recording.eyeLookDownRight)
                }
            } else {
                for recording in relevantRecordings {
                    relevantValues.append(recording.eyeWideLeft)
                    relevantValues.append(recording.eyeSquintLeft)
                    relevantValues.append(recording.eyeBlinkLeft)
                    relevantValues.append(recording.eyeLookUpLeft)
                    relevantValues.append(recording.eyeLookDownLeft)
                }
            }
            break
        //mouth
        case 2:
            //für die region und seite die relevanten werte raussuchen
            if rightSide {
                for recording in relevantRecordings {
                    relevantValues.append(recording.mouthRight)
                    relevantValues.append(recording.mouthSmileRight)
                    relevantValues.append(recording.mouthStretchRight)
                    relevantValues.append(recording.mouthPressRight)
                    relevantValues.append(recording.mouthUpperUpRight)
                    relevantValues.append(recording.mouthFrownRight)
                    relevantValues.append(recording.mouthDimpleRight)
                    relevantValues.append(recording.mouthLowerDownRight)
                }
            } else {
                for recording in relevantRecordings {
                    relevantValues.append(recording.mouthLeft)
                    relevantValues.append(recording.mouthSmileLeft)
                    relevantValues.append(recording.mouthStretchLeft)
                    relevantValues.append(recording.mouthPressLeft)
                    relevantValues.append(recording.mouthUpperUpLeft)
                    relevantValues.append(recording.mouthFrownLeft)
                    relevantValues.append(recording.mouthDimpleLeft)
                    relevantValues.append(recording.mouthLowerDownLeft)
                }
            }
            break
        default:
            print("Diese Region existiert nicht!")
            return 0.0
        }
        
        var max = 0.0
        
        //maximum in relevanten werten finden
        for i in 0...relevantValues.count - 1 {
            if max < Double(relevantValues[i]) {max = Double(relevantValues[i])}
        }
        
        return max
    }
 */
 
    /// Creates a label based on the number of snapshots taken so far
    private func makeLabel(forInstructionStep step: Int) -> String {
        return expressions[step]
            .makeInstructions(forIteration: step)
    }
    
    /// Hides the navigation bar and prepares labels, UI array and segment stepper
    private func setupSegmentView() {
        // Setup segemented stepper for tracking the assessment steps
        var settings = MMTSegmentIndicatorSettings()
        settings.segmentBorderType = .round
        settings.segmentsCount = expressions.count
        settings.segmentWidth = 10
        segment.settings = settings
        segmentUpdatePercentage = 100.0 / Double(expressions.count)
    }
    
    /// Asks the user through an alert if they want to keep the measurements despite them indicating a ptoentially wrongly executed expression
    private func askIsExpressionAcceptable(forInstructionStep step: Int, _ successHandler: @escaping (Bool) -> Void) {
        let actionVerb = expressions[step].makePerformanceVerb()
        let alert = UIAlertController(title: "Are you sure you \(actionVerb)?",
                                      message: nil,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertAction.Style.cancel, handler: { _ in successHandler(true) }))
        alert.addAction(UIAlertAction(title: "Repeat Expression", style: UIAlertAction.Style.default, handler: { _ in successHandler(false) }))
        self.present(alert, animated: true, completion: nil)
    }
    
    /// Calculates the final scores and opens the result view
    private func finishTest() {
        //TODO: calculate scores correctly
        //let scores = calculateDigitalFaceIndex()
        let scores = (total: 0.0, perRegion: [MMTRegion.forehead : 0.0, MMTRegion.eyes : 0.0, MMTRegion.mouth : 0.0])
        CoreData.stack.saveContext()
        //reset recordings
        self.recordings = []
        let homeViewController = MMTFacialNerveHomeViewController()
        //Original: add result view controller here
        self.navigationController?.setViewControllers([homeViewController], animated: true)
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
            newRecording.uuid = currentTestUuid
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
