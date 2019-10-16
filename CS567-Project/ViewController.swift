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

class ViewController: UIViewController, ARSCNViewDelegate {
    var prevNode: SCNNode
    var firstPoint: Bool = true
    
    required init?(coder aDecoder: NSCoder) {
        self.prevNode = SCNNode()
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
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchPosition, types: .existingPlane)
        guard let hitTest = hitTestResults.first else { return }
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        let node = SCNNode(geometry: geometry)
        node.position = SCNVector3(hitTest.worldTransform.columns.3.x, hitTest.worldTransform.columns.3.y, hitTest.worldTransform.columns.3.z)
        
        if (!firstPoint) {
            addLineBetween(start: prevNode.position, end: node.position)
        } else {
            firstPoint = false
        }
        prevNode = node
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func addLineBetween(start: SCNVector3, end: SCNVector3) {
        let lineGeometry = SCNGeometry.lineFrom(vector: start, toVector: end)
        let lineNode = SCNNode(geometry: lineGeometry)
        
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
        
        
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        
//        let node0 = SCNNode(geometry: geometry)
//        node0.position = SCNVector3(planeAnchor.transform.columns.0.x, planeAnchor.transform.columns.0.y, planeAnchor.transform.columns.0.z)
//        sceneView.scene.rootNode.addChildNode(node0)
//
//        let node1 = SCNNode(geometry: geometry)
//        node1.position = SCNVector3(planeAnchor.transform.columns.1.x, planeAnchor.transform.columns.1.y, planeAnchor.transform.columns.1.z)
//        sceneView.scene.rootNode.addChildNode(node1)
//
//        let node2 = SCNNode(geometry: geometry)
//        node2.position = SCNVector3(planeAnchor.transform.columns.2.x, planeAnchor.transform.columns.2.y, planeAnchor.transform.columns.2.z)
//        sceneView.scene.rootNode.addChildNode(node2)
        
        let node3 = SCNNode(geometry: geometry)
        node3.position = SCNVector3(planeAnchor.transform.columns.3.x, planeAnchor.transform.columns.3.y, planeAnchor.transform.columns.3.z)
        sceneView.scene.rootNode.addChildNode(node3)
        
        node.addChildNode(planeNode)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {

        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
         
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
