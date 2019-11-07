//
//  ViewController.swift
//  CS567-Project
//
//  Created by Richard LaFranchi on 10/2/19.
//  Copyright © 2019 Richard LaFranchi. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

extension SCNGeometry {
    class func lineFrom(vector vector1: SCNVector3, toVector vector2: SCNVector3) -> SCNGeometry {
        let indices: [Int32] = [0, 1]
        
        let source = SCNGeometrySource(vertices: [vector1, vector2])
        let element = SCNGeometryElement(indices: indices, primitiveType: .line)
        
        return SCNGeometry(sources: [source], elements: [element])
    }
}

extension ARPlaneAnchor {
    // returns a transform matrix from a point
    func pointTransform(_ x: CGFloat, _ y: CGFloat) -> simd_float4x4 {
        var tf = simd_float4x4(diagonal: simd_float4(repeating: 1))
        tf.columns.3 = simd_float4(x: Float(x), y: 0, z: Float(y), w: 1)
        return tf
    }
    
    var boundaryXYZ: simd_float3x3 {
        get {
            let width = CGFloat(extent.x)
            let height = CGFloat(extent.z)
            var result = simd_float3x3()
            let upperLeftTransform = transform * pointTransform(-width / 2, -height / 2)
            let upperRightTransform = transform * pointTransform(width / 2, -height / 2)
            let bottomLeftTransform = transform * pointTransform(-width / 2, height / 2)
            result.columns.0.x = upperLeftTransform.columns.3.x
            result.columns.0.y = upperLeftTransform.columns.3.y
            result.columns.0.z = upperLeftTransform.columns.3.z
            result.columns.1.x = upperRightTransform.columns.3.x
            result.columns.1.y = upperRightTransform.columns.3.y
            result.columns.1.z = upperRightTransform.columns.3.z
            result.columns.2.x = bottomLeftTransform.columns.3.x
            result.columns.2.y = bottomLeftTransform.columns.3.y
            result.columns.2.z = bottomLeftTransform.columns.3.z
            return result
        }
    }
}

class ViewController: UIViewController, ARSCNViewDelegate {
    var planeAnchors: [ARPlaneAnchor] = [];
    var planeNodes: [SCNNode] = [];
    var building: Building = Building();
    var firstNode: SCNNode!
    var secondNode: SCNNode!
    var lineNode: SCNNode!
    var firstPlane: ARPlaneAnchor!
    var secondPlane: ARPlaneAnchor!
    
    func nodeForAnchor(anchor: ARPlaneAnchor) -> SCNNode! {
        guard let i = planeAnchors.firstIndex(of: anchor) as Int? else {return nil}
        return planeNodes[i]
    }
    
    func setAnchor(node: SCNNode, anchor: ARPlaneAnchor) {
        if let i = planeNodes.firstIndex(of: node) {
            planeAnchors[i] = anchor
        } else {
            planeNodes.append(node)
            planeAnchors.append(anchor)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.debugOptions = [.showFeaturePoints, .showWireframe]
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
    }
    
    fileprivate func selectNode(_ planeAnchor: ARPlaneAnchor) {
        if let node: SCNNode = nodeForAnchor(anchor: planeAnchor) {
            node.geometry?.materials.first?.diffuse.contents = UIColor(displayP3Red: 100, green: 100, blue: 100, alpha: 0.5)
        }
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlane)
        guard let hitTest = hitTestResults.first else { return }
        guard let planeAnchor = hitTest.anchor as? ARPlaneAnchor else { return }
        
        if (firstPlane == nil) {
            firstPlane = planeAnchor
            selectNode(planeAnchor)
        } else if (secondPlane == nil) {
            secondPlane = planeAnchor
            selectNode(planeAnchor)
            findIntersect()
        } else {
            firstPlane = nil
            secondPlane = nil
        }
       
//        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func addLineBetween(start: SCNVector3, end: SCNVector3) {
        let lineGeometry = SCNGeometry.lineFrom(vector: start, toVector: end)
        lineNode = SCNNode(geometry: lineGeometry)
        
        sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
//    func addDistanceText(distance: Float, at point: SCNVector3) {
//        let textGeometry = SCNText(string: String(format: "%.1f\"", distance.metersToInches()), extrusionDepth: 1)
//        textGeometry.font = UIFont.systemFont(ofSize: 10)
//        textGeometry.firstMaterial?.diffuse.contents = UIColor.black
//
//        let textNode = SCNNode(geometry: textGeometry)
//        textNode.position = SCNVector3Make(point.x, point.y, point.z);
//        textNode.scale = SCNVector3Make(0.005, 0.005, 0.005)
//
//        sceneView.scene.rootNode.addChildNode(textNode)
//    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = [.vertical]

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
    fileprivate func findIntersect() {
        if (firstPlane != nil && secondPlane != nil) {
            if (firstNode != nil) { firstNode.removeFromParentNode() }
            if (secondNode != nil) { secondNode.removeFromParentNode() }
            if (lineNode != nil) { lineNode.removeFromParentNode() }
            
            let geometry = SCNSphere(radius: 0.01)
            geometry.firstMaterial?.diffuse.contents = UIColor.red
            
            let planeIntersect: PlaneIntersection = PlaneIntersection(plane1: firstPlane.boundaryXYZ, plane2: secondPlane.boundaryXYZ)
            
            firstNode = SCNNode(geometry: geometry)
            let point1 = planeIntersect.pointAt(y: -1)
            firstNode.position = SCNVector3(x: point1.x, y: -1, z: point1.y)
            sceneView.scene.rootNode.addChildNode(firstNode)
            
            secondNode = SCNNode(geometry: geometry)
            let point2 = planeIntersect.pointAt(y: 1)
            secondNode.position = SCNVector3(x: point2.x, y: 1, z: point2.y)
            sceneView.scene.rootNode.addChildNode(secondNode)
            
            addLineBetween(start: firstNode.position, end: secondNode.position)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor(displayP3Red: 0, green: 0, blue: 0, alpha: 0.5)
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
                
        setAnchor(node: planeNode, anchor: planeAnchor)
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        //        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
//            node.removeFromParentNode() }

        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        setAnchor(node: planeNode, anchor: planeAnchor)

        
//        let geometry = SCNSphere(radius: 0.01)
//        geometry.firstMaterial?.diffuse.contents = UIColor.red
//
//        let node0 = SCNNode(geometry: geometry)
//        node0.position = SCNVector3.init(planeAnchor.boundaryXYZ.columns.0)
//        sceneView.scene.rootNode.addChildNode(node0)
//
//        let node1 = SCNNode(geometry: geometry)
//        node1.position = SCNVector3.init(planeAnchor.boundaryXYZ.columns.1)
//        sceneView.scene.rootNode.addChildNode(node1)
//
//        let node2 = SCNNode(geometry: geometry)
//        node2.position = SCNVector3.init(planeAnchor.boundaryXYZ.columns.2)
//        sceneView.scene.rootNode.addChildNode(node2)
//
//        let node3 = SCNNode(geometry: geometry)
//        node3.position = SCNVector3.init(planeAnchor.boundaryXYZ.columns.3)
//        sceneView.scene.rootNode.addChildNode(node3)
         
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        plane.width = width
        plane.height = height
         
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
                
        planeNode.position = SCNVector3(x, y, z)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
