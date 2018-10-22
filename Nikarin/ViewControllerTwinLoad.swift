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
        
        // Create a new scene
        let scene = SCNScene(named: "DTwins.scnassets/DrillingMachingTwin.dae")!
        // Set the scene to the view
        scnDigitalTwin.scene = scene
        
        //Drill bit's holder rotation
        _drillBitHolder = scene.rootNode.childNode(withName: "AnSpinWheelRoot", recursively: true)!
        
        let anloop = SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 0.1))
        _drillBitHolder?.runAction(anloop)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        scnDigitalTwin.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        scnDigitalTwin.session.pause()
    }
}
