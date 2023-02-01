//
//  MMTBlendShapeLocation.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import Foundation
import ARKit

struct MMTBlendShapeLocation {
    /// True if the BlendShape Location has both a left and a right side, false if it is a middle coefficient
    var isDoubleSided: Bool
    /// The common average value of the BlendShapeLocation, if it is not double sided
    var middleAverage: Double?
    /// The left BlendShapeLocation for the given MMTBlendShapeLocationType, if the BSL is double sided
    var leftBSL: ARFaceAnchor.BlendShapeLocation?
    /// The right BlendShapeLocation for the given MMTBlendShapeLocationType, if the BSL is double sided
    var rightBSL: ARFaceAnchor.BlendShapeLocation?
    /// The right BlendShapeLocation for the given MMTBlendShapeLocationType, if the BSL is not double sided
    var middleBSL: ARFaceAnchor.BlendShapeLocation?
    /// The region to which the BlendShapeLocation belongs
    var region: MMTRegion
}

enum MMTBlendShapeLocationType {
    case browDown,
         browInnerUp,
         browOuterUp,
         cheekPuff,
         cheekSquint,
         eyeBlink,
         eyeSquint,
         mouthDimple,
         mouthFrown,
         mouthLowerDown,
         mouthPress,
         mouthPucker,
         mouthSmile,
         mouthStretch,
         mouthUpperUp,
         noseSneer
    
    /// Creates a MMTBlendShapeLocation for the given MMTBlendShapeLocationType
    func info() -> MMTBlendShapeLocation {
        switch self {
        case .browDown:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.browDownLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.browDownRight,
                                         region: MMTRegion.forehead)
        case .browInnerUp:
            return MMTBlendShapeLocation(isDoubleSided: false,
                                         middleBSL: ARFaceAnchor.BlendShapeLocation.browInnerUp,
                                         region: MMTRegion.forehead)
        case .browOuterUp:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.browOuterUpLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.browOuterUpRight,
                                         region: MMTRegion.forehead)
        case .cheekPuff:
            return MMTBlendShapeLocation(isDoubleSided: false,
                                         middleBSL: ARFaceAnchor.BlendShapeLocation.cheekPuff,
                                         region: MMTRegion.mouth)
        case .cheekSquint:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.cheekSquintLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.cheekSquintRight,
                                         region: MMTRegion.eyes)
        case .eyeBlink:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.eyeBlinkLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.eyeBlinkRight,
                                         region: MMTRegion.eyes)
        case .eyeSquint:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.eyeSquintLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.eyeSquintRight,
                                         region: MMTRegion.eyes)
        case .mouthDimple:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthDimpleLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthDimpleRight,
                                         region: MMTRegion.mouth)
        case .mouthFrown:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthFrownLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthFrownRight,
                                         region: MMTRegion.mouth)
        case .mouthLowerDown:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthLowerDownLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthLowerDownRight,
                                         region: MMTRegion.mouth)
        case .mouthPress:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthPressLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthPressRight,
                                         region: MMTRegion.mouth)
        case .mouthPucker:
            return MMTBlendShapeLocation(isDoubleSided: false,
                                         middleBSL: ARFaceAnchor.BlendShapeLocation.mouthPucker,
                                         region: MMTRegion.mouth)
        case .mouthSmile:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthSmileLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthSmileRight,
                                         region: MMTRegion.mouth)
        case .mouthStretch:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthStretchLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthStretchRight,
                                         region: MMTRegion.mouth)
        case .mouthUpperUp:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.mouthUpperUpLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.mouthUpperUpRight,
                                         region: MMTRegion.mouth)
        case .noseSneer:
            return MMTBlendShapeLocation(isDoubleSided: true,
                                         leftBSL: ARFaceAnchor.BlendShapeLocation.noseSneerLeft,
                                         rightBSL: ARFaceAnchor.BlendShapeLocation.noseSneerRight,
                                         region: MMTRegion.mouth)
        }
    }
}

enum MMTRegion: Double, CaseIterable {
    // Weight of each region for the Facial Nerve algorithm
    case forehead = 0.1, eyes = 0.4, mouth = 0.5
    
    /// Returns a string label for a MMTRegion
    func getLabel() -> String {
        switch self {
        case .forehead: return "Forehead"
        case .eyes: return "Eyes"
        case .mouth: return "Mouth"
        }
    }
}
