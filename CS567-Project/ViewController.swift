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

class EventNode: Equatable, CustomStringConvertible {
    var type: String = "SELECT"
    var node: RipperNode
    var visited: Bool = false
    init(node: SCNNode) {
        self.node = RipperNode(node: node)
    }
    
    init(node: RipperNode) {
        self.node = node
    }
    
    static func == (lhs: EventNode, rhs: EventNode) -> Bool {
        return lhs.node == rhs.node
    }
    
    public var description: String {
        return "\(type) \(node)"
    }
}

class EventFlowEdge: Equatable, CustomStringConvertible {
    var from: EventNode
    var to: EventNode
    init(from: EventNode, to: EventNode) {
        self.from = from
        self.to = to
    }
    
    static func == (lhs: EventFlowEdge, rhs: EventFlowEdge) -> Bool {
        return lhs.from == rhs.from && lhs.to == rhs.to
    }
    
    public var description: String {
        return "from: \(from), to: \(to)"
    }
}

class EventFlowGraph: CustomStringConvertible {
    var vertices: [EventNode] = []
    var edges: [EventFlowEdge] = []
    
    var ripperNodes: [RipperNode] {
        get {
            var nodes: [RipperNode] = []
            for vertex in vertices {
                nodes.append(vertex.node)
            }
            return nodes
        }
    }
    
    init() {}
    
    func addVertex(node: RipperNode) {
        if (!ripperNodes.contains(node)) {
            vertices.append(EventNode(node: node))
        }
    }
    
    func addEdge(e: EventFlowEdge) {
        print("ADDING EDGE: \(e)")
        if !vertices.contains(e.from) {
            vertices.append(e.from)
        }
        if !vertices.contains(e.to) {
            vertices.append(e.to)
        }
        if !edges.contains(e) {
            edges.append(e)
        }
    }
    
    func addEdge(from: SCNNode, to: RipperNode) {
        let edge = EventFlowEdge(from: checkExisting(node: from), to: EventNode(node: to))
        addEdge(e: edge)
    }
    
    func addEdge(from: RipperNode, to: SCNNode) {
        let edge = EventFlowEdge(from: EventNode(node: from), to: checkExisting(node: to))
        addEdge(e: edge)
    }
    
    func addEdge(from: RipperNode, to: RipperNode) {
        let edge = EventFlowEdge(from: EventNode(node: from), to: EventNode(node: to))
        addEdge(e: edge)
    }
    
    func checkExisting(node: SCNNode) -> EventNode {
        for (i, ripper) in ripperNodes.enumerated() {
            if ripper.scnNode == node {
                return vertices[i]
            }
        }
        
        let eventNode: EventNode = EventNode(node: RipperNode(node: node))
        return eventNode
    }
    
    public var description: String {
        return "Vertices: \(vertices)\nEdges: \(edges)"
    }
    
    func generateTestCases() {
        // get first vertex in the list
        for vertex in vertices {
            vertex.visited = false
        }
        let source = vertices[0]
        let destination = vertices[vertices.count - 1]
        var path = [String]()
        var paths = [[String]]()
        getAllPaths(source, destination, &path, &paths)
        exportCSV(paths)
    }
    
    func exportCSV(_ paths: [[String]]) {
        var csvString = ""
        for path in paths {
            csvString += path.joined(separator: ",")
            csvString += "\n"
        }
        do {

            let path = try FileManager.default.url(for: .documentDirectory,
                                                   in: .allDomainsMask,
                                                   appropriateFor: nil,
                                                   create: false)

            let fileURL = path.appendingPathComponent("TestCases\(Date()).csv")
            try csvString.write(to: fileURL, atomically: true , encoding: .utf8)
        } catch {
            print("error creating file")
        }
    }
    
    func getAllPaths(_ source: EventNode, _ destination: EventNode, _ path: inout [String], _ paths: inout [[String]]) {
        source.visited = true
        path.append(source.description)
        
        if source == destination {
            print(path)
            paths.append(path)
        } else {
            for node in neighbors(node: source) {
                if !node.visited {
                    getAllPaths(node, destination, &path, &paths)
                }
            }
        }
        path.popLast()
        source.visited = false
    }
    
    func neighbors(node: EventNode) -> [EventNode] {
        var neighs: [EventNode] = []
        for edge in edges {
            if edge.from == node {
                neighs.append(edge.to)
            }
        }
        return neighs
    }
}

class RipperNode: Equatable, CustomStringConvertible {
    static var nextVal = 1;
    static var nextValWalls = 1;
    static var nextValNodes = 1;
    var visits: Int = 0
    var id: Int = 0
    var scnNode: SCNNode
    var children: [RipperNode] = []
    init(node: SCNNode) {
        id = RipperNode.nextVal
        RipperNode.nextVal += 1
        scnNode = node
        if (node.geometry != nil) {
            if node.geometry is SCNPlane {
                id = RipperNode.nextValWalls
                RipperNode.nextValWalls += 1
            }
            if node.geometry is SCNSphere {
                id = RipperNode.nextValNodes
                RipperNode.nextValNodes += 1
            }
        }
    }
    
    func addChild(node: SCNNode) {
        children.append(RipperNode(node: node))
    }
    
    func addChildren(nodes: [RipperNode]) {
        children = children + nodes
    }
    
    static func == (lhs: RipperNode, rhs: RipperNode) -> Bool {
        return lhs.scnNode == rhs.scnNode
    }
    
    public var description: String {
        if (scnNode.geometry is SCNPlane) {
            return "Wall \(id)"
        } else if (scnNode.geometry is SCNSphere) {
            return "Corner \(id)"
        } else {
            return "Node \(id)"
        }
    }
}

class RipperForest {
    // top level 3D objects
    var topLevelNodes: [RipperNode] = []
    var allNodes: [RipperNode] = []
    var viewController: ViewController
    var efg: EventFlowGraph
    var nodeLabels = [String: SCNNode]()
    var currentRipper: RipperNode!
    var nextRipper: RipperNode!
    
    var allSceneNodes: [SCNNode] {
        get {
            var nodes: [SCNNode] = []
            for node in viewController.sceneView.scene.rootNode.childNodes {
                recurseSceneNode(node: node, &nodes)
            }
            return nodes
        }
    }
    
    func recurseSceneNode(node: SCNNode, _ nodes: inout [SCNNode]) {
        if isExecutable(widget: node) {
            nodes.append(node)
        }
        for c in node.childNodes {
            recurseSceneNode(node: c, &nodes)
        }
    }
    
    init(viewController: ViewController) {
        self.viewController = viewController
        self.efg = EventFlowGraph()
        for node in allSceneNodes {
            let ripper = RipperNode(node: node)
            allNodes.append(ripper)
            topLevelNodes.append(ripper)
        }
        print("TOP level: \(topLevelNodes)")
    }
    
    func dfs() {
        for node: RipperNode in topLevelNodes {
            dfsRecursive(node: node)
        }
        for (text, node) in nodeLabels {
            viewController.addText(string: text, parent: node)
        }
        print("EVENT FLOW GRAPH")
        print(efg)
        for edge in efg.edges {
            viewController.addLineBetween(start: edge.from.node.scnNode.position, end: edge.from.node.scnNode.position)
        }
        efg.generateTestCases()
    }
    
    func dfsRecursive(node: RipperNode) {
        if (currentRipper != nil) {
            efg.addEdge(from: currentRipper, to: node)
        }
        currentRipper = node
        nodeLabels[node.description] = node.scnNode
        print("DFS STEP: \(node)")
        let widgets: [SCNNode] = [node.scnNode];
        print("WIDGETS")
        print(widgets)
        for widget in widgets {
            execute(widget: widget)
            print("executed widget in \(node)")
            let c = invokedNodes()
            node.addChildren(nodes: c)
            for child in c {
                efg.addEdge(from: widget, to: child)
                dfsRecursive(node: child)
            }
        }
    }
    
    fileprivate func isExecutable(widget: SCNNode) -> Bool {
        if widget.geometry == nil { return false }
        guard let geometry = widget.geometry as? SCNPlane else {
            guard let geometry = widget.geometry as? SCNSphere else {
                return false
            }
            return true
        }
        return true
    }
    
    fileprivate func execute(widget: SCNNode) {
        if widget.geometry is SCNSphere {
            viewController.selectCorner(widget)
        } else if widget.geometry is SCNPlane {
            viewController.selectPlane(widget)
        }
    }
    
    fileprivate func invokedNodes() -> [RipperNode] {
        var invoked: [RipperNode] = []
        var existing: [SCNNode] = []
        for node in allNodes {
            existing.append(node.scnNode)
        }
        for scnNode in allSceneNodes {
            if !existing.contains(scnNode) {
                invoked.append(RipperNode(node: scnNode))
            }
        }
        allNodes = allNodes + invoked
        return invoked
    }
}

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
    var planeAnchors: [ARPlaneAnchor] = []
    var planeNodes: [SCNNode] = []
    var buildCornerNodes: [SCNNode] = []
    var selectedBuildingcornerNodes: [SCNNode] = []
    var buildingLineNodes: [SCNNode] = []
    var selectedeNodes: [Int] = []
    var building: Building = Building()
    var intersectToCorner = [String: Int]()
    
    var rippButton:UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Rip", for: .normal)
        btn.setTitleColor(.black, for: .normal)
        btn.backgroundColor = .white
        btn.frame = CGRect(x: 0, y: 0, width: 110, height: 60)
        btn.center = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height*0.90)
        btn.layer.cornerRadius = btn.bounds.height/2
        btn.tag = 0
        return btn
    }()
    
    fileprivate func cornerForIntersect(i: Int, j: Int) -> SCNNode! {
        if let k = intersectToCorner["\(i)\(j)"] {
            return buildCornerNodes[k]
        } else {
            return nil
        }
    }
    
    fileprivate func setCornerForInterset(i: Int, j: Int, node: SCNNode) {
        intersectToCorner["\(i)\(j)"] = buildCornerNodes.firstIndex(of: node)
    }
    
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
        
        sceneView.showsLargeContentViewer = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
        self.view.addSubview(rippButton)
        
        rippButton.addTarget(self, action: #selector(self.rippAction(sender:)), for: .touchUpInside)

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
    
    fileprivate func selectCorner(_ cornerNode: SCNNode) {
        let geometry = SCNSphere(radius: 0.02)
        geometry.firstMaterial?.diffuse.contents = UIColor.green
        cornerNode.geometry = geometry
        if !selectedBuildingcornerNodes.contains(cornerNode) {
            selectedBuildingcornerNodes.append(cornerNode)
        }
        drawLines()
    }
    
    @objc func tapped(gesture: UITapGestureRecognizer) {
        let touchPosition: CGPoint = gesture.location(in: sceneView)
        handleHitTest(touchPosition: touchPosition)
    }
    
    @objc func rippAction(sender: UIButton) {
        let forest = RipperForest(viewController: self)
        forest.dfs()
    }
    
    fileprivate func selectPlane(_ node: SCNNode) {
        if planeNodes.contains(node) {
            if isNodeSelected(node) {
                deselectNode(node)
            } else {
                selectNode(node)
            }
            findIntersect()
        }
    }
    
    func handleHitTest(touchPosition: CGPoint) {
        print (touchPosition)
        let hitTestResults = sceneView.hitTest(touchPosition)
        guard let hitTest = hitTestResults.first else { return }
        guard let textElement = hitTest.node.geometry as? SCNText else {
            if hitTest.node.geometry is SCNPlane {
                selectPlane(hitTest.node)
            } else if hitTest.node.geometry is SCNSphere {
                selectCorner(hitTest.node)
            }
            return
        }
        
        guard let text: String = textElement.string as? String else { return }

        if text == "SELECT" {
            let green = UIColor.green
            textElement.materials.first?.diffuse.contents = green
            guard let cornerNode: SCNNode = hitTest.node.parent else {return}
            selectCorner(cornerNode)
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
        
        let geometry = SCNSphere(radius: 0.01)
        geometry.firstMaterial?.diffuse.contents = UIColor.red
        
        for (i, selected) in selectedeNodes.enumerated() {
            if selected == 1 {
                for (j, selectedJ) in selectedeNodes.enumerated() {
                    if selectedJ == 1 && j != i {
                        let firstPlane = planeAnchors[i]
                        let secondPlane = planeAnchors[j]
                        
                        let planeIntersect: PlaneIntersection = PlaneIntersection(plane1: firstPlane.boundaryXYZ, plane2: secondPlane.boundaryXYZ)
                        let point1 = planeIntersect.pointAt(y: 0)
                        
                        if let node = cornerForIntersect(i: i, j: j) {
                            print("node found")
                            node.position = SCNVector3(x: point1.x, y: 0, z: point1.y)
                        } else if let node = cornerForIntersect(i: j, j: i) {
                            print("node found")
                            node.position = SCNVector3(x: point1.x, y: 0, z: point1.y)
                        } else {
                            print("node NOT found")
                            let node = SCNNode(geometry: geometry)
                            node.position = SCNVector3(x: point1.x, y: 0, z: point1.y)
                            buildCornerNodes.append(node)
                            setCornerForInterset(i: i, j: j, node: node)
                            setCornerForInterset(i: j, j: i, node: node)
                            sceneView.scene.rootNode.addChildNode(node)
                        }
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
