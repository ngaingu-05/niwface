//
//  Enums.swift
//  Nerve-ous
//
//  Created by Lara Marie Reimer on 01.02.23.
//

import Foundation

enum RecordingType: Int, CaseIterable {
    case eyeBlinkLR,
         eyeLookDownLR,
         eyeLookRight,
         eyeLookLeft,
         eyeLookUpLR,
         eyeSquintLR,
         eyeWideLR,
         jawForward,
         jawLeft,
         jawRight,
         jawOpen,
         mouthClose,
         mouthFunnel,
         mouthPucker,
         mouthLeft,
         mouthRight,
         mouthSmileLR,
         mouthFrownLR,
         mouthDimpleLR,
         mouthStretchLR,
         mouthRollLower,
         mouthRollUpper,
         mouthShrugLower,
         mouthShrugUpper,
         mouthPressLR,
         mouthLowerDownLR,
         mouthUpperUpLR,
         browDownLR,
         browInnerUp,
         browOuterUpLeft,
         browOuterUpRight,
         cheekPuff,
         cheekSquintLR,
         noseSneerLeft,
         noseSneerRight,
         tongueOut,
         anger,
         fear,
         disgust,
         joy,
         sadness,
         surprise,
         contempt
    
    var description: String {
        switch self {
        case .eyeBlinkLR:
            return "eyeBlinkLR"
        case .eyeLookDownLR:
            return "eyeLookDownLR"
        case .eyeLookRight:
            return "eyeLookRight"
        case .eyeLookLeft:
            return "eyeLookLeft"
        case .eyeLookUpLR:
            return "eyeLookUpLR"
        case .eyeSquintLR:
            return "eyeSquintLR"
        case .eyeWideLR:
            return "eyeWideLR"
        case .jawForward:
            return "jawForward"
        case .jawLeft:
            return "jawLeft"
        case .jawRight:
            return "jawRight"
        case .jawOpen:
            return "jawOpen"
        case .mouthClose:
            return "mouthClose"
        case .mouthFunnel:
            return "mouthFunnel"
        case .mouthPucker:
            return "mouthPucker"
        case .mouthLeft:
            return "mouthLeft"
        case .mouthRight:
            return "mouthRight"
        case .mouthSmileLR:
            return "mouthSmileLR"
        case .mouthFrownLR:
            return "mouthFrownLR"
        case .mouthDimpleLR:
            return "mouthDimpleLR"
        case .mouthStretchLR:
            return "mouthStretchLR"
        case .mouthRollLower:
            return "mouthRollLower"
        case .mouthRollUpper:
            return "mouthRollUpper"
        case .mouthShrugLower:
            return "mouthShrugLower"
        case .mouthShrugUpper:
            return "mouthShrugUpper"
        case .mouthPressLR:
            return "mouthPressLR"
        case .mouthLowerDownLR:
            return "mouthLowerDownLR"
        case .mouthUpperUpLR:
            return "mouthUpperUpLR"
        case .browDownLR:
            return "browDownLR"
        case .browInnerUp:
            return "browInnerUp"
        case .browOuterUpLeft:
            return "browOuterUpLeft"
        case .browOuterUpRight:
            return "browOuterUpRight"
        case .cheekPuff:
            return "cheekPuff"
        case .cheekSquintLR:
            return "cheekSquintLR"
        case .noseSneerLeft:
            return "noseSneerLeft"
        case .noseSneerRight:
            return "noseSneerRight"
        case .tongueOut:
            return "tongueOut"
        case .anger:
            return "anger"
        case .fear:
            return "fear"
        case .disgust:
            return "disgust"
        case .joy:
            return "joy"
        case .sadness:
            return "sadness"
        case .surprise:
            return "surprise"
        case .contempt:
            return "contempt"
        default:
            return "None"
        }
    }
}
