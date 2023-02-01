/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A simple cartoon character animated using ARKit blend shapes.
*/

import Foundation
import SceneKit
import ARKit

/// - Tag: BlendShapeCharacter
class BlendShapeCharacter: NSObject, VirtualContentController {
    
    var contentNode: SCNNode?

    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        return contentNode
    }
    
    /// - Tag: BlendShapeAnimation
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        return
    }
}
