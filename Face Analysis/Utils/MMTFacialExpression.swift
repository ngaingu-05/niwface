//
//  MMTFacialExpression.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import ARKit

enum MMTFacialExpression {
    // Expression types
    case smile, closedEyes, puffedCheeks, raisedEyebrows, pursedLips
    
    /// Creates the String label for each expression
    func getString() -> String {
        var text = ""
        switch self {
        case .smile:
            text = "smile"
        case .closedEyes:
            text = "closedEyes"
        case .puffedCheeks:
            text = "puffedCheeks"
        case .raisedEyebrows:
            text = "raisedEyebrows"
        case .pursedLips:
            text = "pursedLips"
        }
        return text
    }
    
    /// Creates the instructions for each expression
    func makeInstructions(forIteration step: Int) -> String {
        var instruction = ""
        switch self {
        case .smile:
            instruction = "Smile with your mouth open"
        case .closedEyes:
            instruction = "Close your eyes with netural expession"
        case .puffedCheeks:
            instruction = "Puff your cheeks\n(fill them with air)"
        case .raisedEyebrows:
            instruction = "Raise your eyebrows\n(as if surprised)"
        case .pursedLips:
            instruction = "Purse your lips\n(as if whistling)"
        }
        return instruction + " (\(step + 1)/5)"
    }
    
    /// Creates a past continous String describing th conduction of the action
    func makePerformanceVerb() -> String {
        switch self {
        case .smile:
            return "were smiling"
        case .closedEyes:
            return "had your eyes closed"
        case .puffedCheeks:
            return "were puffing your cheeks"
        case .raisedEyebrows:
            return "had your eyebrows raised"
        case .pursedLips:
            return "were pursing your lips"
        }
    }
    
    /// Assesses if the captured coefficient reach the minimal r´threshold set for the facial expression
    func hasAcceptablePerformance(withCoefficients bsl: [ARFaceAnchor.BlendShapeLocation: NSNumber]) -> Bool {
        let highTreshold = 0.6
        let lowThreshold = 0.3
        
        switch self {
        case .smile:
            return bsl[.mouthSmileLeft]?.doubleValue ?? 0.0 >= highTreshold || bsl[.mouthSmileRight]?.doubleValue ?? 0.0 >= highTreshold
        case .closedEyes:
            return bsl[.eyeBlinkLeft]?.doubleValue ?? 0.0 >= highTreshold || bsl[.eyeBlinkRight]?.doubleValue ?? 0.0 >= highTreshold
        case .puffedCheeks:
            return bsl[.cheekPuff]?.doubleValue ?? 0.0 >= highTreshold
        case .raisedEyebrows:
            return bsl[.browOuterUpLeft]?.doubleValue ?? 0.0 >= lowThreshold
            || bsl[.browOuterUpRight]?.doubleValue ?? 0.0 >= lowThreshold
            || bsl[.browInnerUp]?.doubleValue ?? 0.0 >= lowThreshold
        case .pursedLips:
            return bsl[.mouthPucker]?.doubleValue ?? 0.0 >= highTreshold
        }
    }
}
