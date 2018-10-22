//
//  ViewControllerTwinLoad.swift
//  Nikarin
//
//  Created by Alpha on 22/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class ViewControllerTwinLoad: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet weak var scnDigitalTwin: ARSCNView!
    var _drillBitHolder : SCNNode?
    var _ActionApplied : Bool = false
    
    @IBAction func CloseView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        scnDigitalTwin.delegate = self
        
        // Show statistics such as fps and timing information
        scnDigitalTwin.showsStatistics = false
        
        //scnDigitalTwin.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        
        //Get Tapgesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewControllerTwinLoad.addTwinImageToScene(withGestureRecognizer:)))
        scnDigitalTwin.addGestureRecognizer(tapGestureRecognizer)
        
        /*// Create a new scene
        let scene = SCNScene(named: "DTwins.scnassets/DrillingMachingTwin.dae")!
        // Set the scene to the view
        scnDigitalTwin.scene = scene*/
  

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        scnDigitalTwin.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        scnDigitalTwin.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.gray
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    @IBAction func ApplyAction(_ sender: UIButton) {
        
        if _drillBitHolder == nil {
            return
        }
        
        if _ActionApplied == false {
            let anloop = SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 0.1))
            _drillBitHolder?.runAction(anloop)
            _ActionApplied = true
        }
        else {
            _drillBitHolder?.removeAllActions()
            _ActionApplied = false
        }
    }
    
    @objc func addTwinImageToScene(withGestureRecognizer recognizer: UIGestureRecognizer) {
        let tapLocation = recognizer.location(in: scnDigitalTwin)
        let hitTestResults = scnDigitalTwin.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        print ("hittestresults func called")
        guard let hitTestResult = hitTestResults.first else {
            print ("hittestresults else returned")
            return }
        let translation = hitTestResult.worldTransform.columns.3
        
        guard let twinImgScene = SCNScene(named: "DTwins.scnassets/DrillingMachingTwin.dae"),
            let shipNode = twinImgScene.rootNode.childNode(withName: "SketchUp", recursively: false)
            else {
                print("ship.scn return")
                return
        }
        print ("adding node here")
        
        //Drill bit's holder rotation
        _drillBitHolder = twinImgScene.rootNode.childNode(withName: "AnSpinWheelRoot", recursively: true)!
        shipNode.position = SCNVector3(translation.x, translation.y, translation.z)
        scnDigitalTwin.scene.rootNode.addChildNode(shipNode)
    }
}
