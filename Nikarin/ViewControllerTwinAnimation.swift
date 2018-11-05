//
//  ViewControllerTwinAnimation.swift
//  Nikarin
//
//  Created by Alpha on 01/11/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import Foundation
import UIKit
import ARKit
import SceneKit

class ViewControllerTwinAnimation: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet weak var scnViewAnimation: ARSCNView!
    
    var _trainingTwinNode : SCNNode?
    var anEngineNodes : [SCNNode] = [SCNNode]()
    var strArrayNodesToMove : [String] = [String]()
    var _iPosActual:Double = -20.0
    var _iNodeCounter = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        self.scnViewAnimation.delegate = self
        
        // Show statistics such as fps and timing information
        scnViewAnimation.showsStatistics = false
        
        scnViewAnimation.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        strArrayNodesToMove.append("AllScrews")
        strArrayNodesToMove.append("group_1")
        strArrayNodesToMove.append("group_14")
        strArrayNodesToMove.append("group_7")
        
        //Get Tapgesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewControllerTwinAnimation.addTwinImageToScene(withGestureRecognizer:)))
        scnViewAnimation.addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc func addTwinImageToScene(withGestureRecognizer recognizer: UIGestureRecognizer) {
        if _trainingTwinNode != nil {
            return
        }
        let tapLocation = recognizer.location(in: scnViewAnimation)
        let hitTestResults = scnViewAnimation.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        guard let hitTestResult = hitTestResults.first else {
            return }
        let translation = hitTestResult.worldTransform.columns.3
        
        //DrillingMachingTwin.dae, model 2.dae
        guard let twinImgScene = SCNScene(named: "DTwins.scnassets/ElectricMotor.dae"),
            let shipNode = twinImgScene.rootNode.childNode(withName: "SketchUp", recursively: false)
            else {
                print("scene not found return")
                return
        }
        
        scnViewAnimation.autoenablesDefaultLighting = false
        
        //Drill bit's holder rotation
        _trainingTwinNode = twinImgScene.rootNode.childNode(withName: "SketchUp", recursively: false)!
        
        strArrayNodesToMove.forEach { item in
            print(item)
            guard let anSCNNode = twinImgScene.rootNode.childNode(withName: String(item), recursively: true)
                else { return }
            print(anSCNNode)
            anEngineNodes.append(anSCNNode)
        }
        
        shipNode.position = SCNVector3(translation.x, translation.y, translation.z)
        scnViewAnimation.scene.rootNode.addChildNode(shipNode)
        setupAmbientLight()
        setupOmniDirectionalLight()        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        // Run the view's session
        scnViewAnimation.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        scnViewAnimation.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        if _trainingTwinNode != nil {
            return
        }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.gray
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,0,z)
        planeNode.opacity = 0.15
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    
    @IBAction func clickRefresh(_ sender: UIButton) {
        
        if _iNodeCounter < anEngineNodes.count { return }
        
        sender.press(completion:{ finish in
            if finish {
                print("animation ended - refresh")
            }
        })
        
        let iPostition:Double = -5.0
        var iPosActual:Double = 20.0
        anEngineNodes.forEach { item in
            print(item)
            //item.removeAllActions()
            //item.runAction(SCNAction.rever)
            let wait:SCNAction = SCNAction.wait(duration: 3)
            
            let anLoopAction = SCNAction.move(by: SCNVector3(iPosActual,0,0), duration: 3)
            //let anSCNNode = anEngineNodes[_iNodeCounter]
            item.runAction(SCNAction.sequence([anLoopAction, wait]))
            
            iPosActual = iPosActual + iPostition
        }
        
        _iNodeCounter = 0
        
    }
    
    @IBAction func clickNextStep(_ sender: UIButton) {
        
        sender.press(completion:{ finish in
            if finish {
                print("animation ended - next step")
            }
        })
        
        if _iNodeCounter >= anEngineNodes.count { return }
        let iPostition:Double = 5.0
        let wait:SCNAction = SCNAction.wait(duration: 10)
        
        let anLoopAction = SCNAction.move(by: SCNVector3(_iPosActual,0,0), duration: 5)
        let anSCNNode = anEngineNodes[_iNodeCounter]
        anSCNNode.runAction(SCNAction.sequence([anLoopAction, wait]))
        
        _iPosActual = _iPosActual + iPostition
        _iNodeCounter = _iNodeCounter + 1
    }    
    
    @IBAction func clickClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    private func setupAmbientLight() {
        
        // setup ambient light source
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor(white: 0.53, alpha: 1.0).cgColor
        
        scnViewAnimation.scene.rootNode.addChildNode(ambientLightNode)
    }
    
    private func setupOmniDirectionalLight() {
        
        // initialize noe
        let omniLightNode = SCNNode()
        // assign light
        omniLightNode.light = SCNLight()
        // set type
        omniLightNode.light!.type = SCNLight.LightType.omni
        // color and position
        omniLightNode.light!.color = UIColor(white: 0.56, alpha: 1.0).cgColor
        omniLightNode.position = SCNVector3Make(0.0, 2000.0, 0.0)
        
        scnViewAnimation.scene.rootNode.addChildNode(omniLightNode)
    }
    
}
