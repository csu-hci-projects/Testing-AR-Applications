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
    var buildCornerNodes: [SCNNode] = [];
    var selectedBuildingcornerNodes: [SCNNode] = [];
    var buildingLineNodes: [SCNNode] = [];
    var selectedeNodes: [Int] = [];
    var building: Building = Building();
//    var firstNode: SCNNode!
//    var secondNode: SCNNode!
//    var lineNode: SCNNode!
//    var firstPlane: ARPlaneAnchor!
//    var secondPlane: ARPlaneAnchor!
    
    fileprivate func nodeForAnchor(_ anchor: ARPlaneAnchor) -> SCNNode! {
        if let i = planeAnchors.firstIndex(of: anchor) {
            return planeNodes[i]
        } else {
            return nil
        }
    }
    
    fileprivate func anchorForNode(node: SCNNode) -> ARPlaneAnchor! {
        if let i = planeNodes.firstIndex(of: node) {
            return planeAnchors[i]
        } else {
            return nil
        }
    }
    
    fileprivate func setAnchor(node: SCNNode, anchor: ARPlaneAnchor) {
        if let i = planeNodes.firstIndex(of: node) {
            planeAnchors[i] = anchor
        } else {
            planeNodes.append(node)
            planeAnchors.append(anchor)
            selectedeNodes.append(0)
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
    
    fileprivate func selectNode(_ node: SCNNode) {
        if let i = planeNodes.firstIndex(of: node) {
            selectedeNodes[i] = 1
        }
        node.geometry?.materials.first?.diffuse.contents = UIColor(displayP3Red: 0, green: 1.0, blue: 0, alpha: 0.5)
    }
    
    fileprivate func selectNode(_ planeAnchor: ARPlaneAnchor) {
        if let node: SCNNode = nodeForAnchor(planeAnchor) {
            selectNode(node)
        }
    }
    
    fileprivate func deselectNode(_ node: SCNNode) {
        if let i = planeNodes.firstIndex(of: node) {
            selectedeNodes[i] = 0
        }
        node.geometry?.materials.first?.diffuse.contents = UIColor(displayP3Red: 0, green: 0.0, blue: 0, alpha: 0.5)
    }
    
    fileprivate func deselectNode(_ planeAnchor: ARPlaneAnchor) {
        if let node: SCNNode = nodeForAnchor(planeAnchor) {
            selectNode(node)
        }
    }
    
    fileprivate func isNodeSelected(_ node: SCNNode) -> Bool {
        if let i = planeNodes.firstIndex(of: node) {
            return selectedeNodes[i] == 1
        } else {
            return false
        }
    }
    
    fileprivate func selectNewNode(_ cornerNode: SCNNode, _ hitTest: SCNHitTestResult) {
        let geometry = SCNSphere(radius: 0.02)
        geometry.firstMaterial?.diffuse.contents = UIColor.green
        let newNode = SCNNode(geometry: geometry)
        newNode.position = cornerNode.position
        hitTest.node.removeFromParentNode()
        cornerNode.removeFromParentNode()
        selectedBuildingcornerNodes.append(cornerNode)
        drawLines()
        sceneView.scene.rootNode.addChildNode(newNode)
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        let touchPosition = gesture.location(in: sceneView)
        let hitTestResults = sceneView.hitTest(touchPosition)
        guard let hitTest = hitTestResults.first else { return }
        guard let textElement = hitTest.node.geometry as? SCNText else {
            guard let sphereElement = hitTest.node.geometry as? SCNSphere else {
                if planeNodes.contains(hitTest.node) {
                    if isNodeSelected(hitTest.node) {
                        deselectNode(hitTest.node)
                    } else {
                        selectNode(hitTest.node)
                    }
                    findIntersect()
                }
                return
            }
            selectNewNode(hitTest.node, hitTest)
            return
        }
        
        print(hitTest.node)
        guard let text: String = textElement.string as? String else { return }
        print(text)
        print(buildCornerNodes.count)

        if text == "SELECT" {
            let green = UIColor.green
            textElement.materials.first?.diffuse.contents = green
            guard let cornerNode: SCNNode = hitTest.node.parent else {return}
            selectNewNode(cornerNode, hitTest)
        }
    }
    
    func drawLines() {
        for node in buildingLineNodes {
            node.removeFromParentNode()
        }
        buildingLineNodes = [];
        for (i,node) in selectedBuildingcornerNodes.enumerated() {
            if (i < selectedBuildingcornerNodes.count-1) {
                let from = node.position
                let to = selectedBuildingcornerNodes[i+1].position
                addLineBetween(start: from, end: to)
                addDistanceText(distance: distance(from: from, to: to), at: midpoint(from: from, to: to))
            }
        }
    }
    
    func addLineBetween(start: SCNVector3, end: SCNVector3) {
        let lineGeometry = SCNGeometry.lineFrom(vector: start, toVector: end)
        let lineNode = SCNNode(geometry: lineGeometry)
        lineNode.geometry?.materials.first?.diffuse.contents = UIColor.green
        sceneView.scene.rootNode.addChildNode(lineNode)
    }
    
    func createTextNode(string: String) -> SCNNode {
        let text = SCNText(string: string, extrusionDepth: 0.1)
        text.font = UIFont.systemFont(ofSize: 1.0)
        text.flatness = 0.005
        text.firstMaterial?.diffuse.contents = UIColor.red

        let textNode = SCNNode(geometry: text)

        let fontSize = Float(0.04)
        textNode.scale = SCNVector3(fontSize, fontSize, fontSize)

        return textNode
    }
    
    func addText(string: String, parent: SCNNode) {
        let textNode = self.createTextNode(string: string)
        textNode.position = SCNVector3Zero

        parent.addChildNode(textNode)
    }
    
    func midpoint(from: SCNVector3, to: SCNVector3) -> SCNVector3 {
        let x = from.x + ((to.x - from.x)/2)
        let y = from.y + ((to.y - from.y)/2)
        let z = from.z + ((to.z - from.z)/2)

        return SCNVector3(x, y, z)
    }
    
    func distance(from: SCNVector3, to: SCNVector3) -> Float {
        let toxSq = pow(to.x - from.x, 2)
        let toySq = pow(to.y - from.y, 2)
        let tozSq = pow(to.z - from.z, 2)
        return sqrtf(toxSq + toySq + tozSq)
    }
    
    func addDistanceText(distance: Float, at point: SCNVector3) {
        let textGeometry = SCNText(string: String(format: "%.1f ft", distance*3.28084), extrusionDepth: 1)
        textGeometry.font = UIFont.systemFont(ofSize: 10)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.black

        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3Make(point.x, point.y, point.z);
        textNode.scale = SCNVector3Make(0.005, 0.005, 0.005)

        sceneView.scene.rootNode.addChildNode(textNode)
    }
    
    
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
        for node in buildCornerNodes {
            node.removeFromParentNode()
        }
        buildCornerNodes = []
        
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        
        for (i, selected) in selectedeNodes.enumerated() {
            if selected == 1 {
                for (j, selectedJ) in selectedeNodes.enumerated() {
                    if selectedJ == 1 && j != i {
                        let firstPlane = planeAnchors[i]
                        let secondPlane = planeAnchors[j]
                        
                        let planeIntersect: PlaneIntersection = PlaneIntersection(plane1: firstPlane.boundaryXYZ, plane2: secondPlane.boundaryXYZ)
                        
                        let node = SCNNode(geometry: geometry)
                        let point1 = planeIntersect.pointAt(y: 0)
                        node.position = SCNVector3(x: point1.x, y: 0, z: point1.y)
                        buildCornerNodes.append(node)
                        // addText(string: "SELECT", parent: node)
                        sceneView.scene.rootNode.addChildNode(node)
                    }
                }
            }
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

        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        setAnchor(node: planeNode, anchor: planeAnchor)
         
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
