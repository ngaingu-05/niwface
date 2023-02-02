//
//  MMTTexturedFace.swift
//  Nerve-ous
//
//  Created by Céline Aldenhoven on 10.07.22.
//

import ARKit
import SceneKit

class MMTTexturedFace: NSObject, VirtualContentController {
    var contentNode: SCNNode?
    
    /// - Tag: CreateARSCNFaceGeometry
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let sceneView = renderer as? ARSCNView,
            anchor is ARFaceAnchor else { return nil }
        
        #if targetEnvironment(simulator)
        // swiftlint:disable line_length
        print("WARNING: Facial Analysis -- ARKit is not supported in iOS Simulator. Connect a physical iOS device and select it as your Xcode run destination, or select Generic iOS Device as a build-only destination.")
        #else
        let faceGeometry = ARSCNFaceGeometry(device: sceneView.device!)!
        let material = faceGeometry.firstMaterial!
        
        material.diffuse.contents = #imageLiteral(resourceName: "wireframeTexture") // Example texture map image.
        material.lightingModel = .physicallyBased
        
        contentNode = SCNNode(geometry: faceGeometry)
        #endif
        return contentNode
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceGeometry = node.geometry as? ARSCNFaceGeometry,
            let faceAnchor = anchor as? ARFaceAnchor
            else { return }
        
        faceGeometry.update(from: faceAnchor.geometry)
    }
}
