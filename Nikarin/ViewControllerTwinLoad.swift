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
    
    //Current Device ID & end point details
    var oNikarinUtility: NikarinUtility = NikarinUtility()
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    
    var timerReadFromServer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        scnDigitalTwin.delegate = self
        
        // Show statistics such as fps and timing information
        scnDigitalTwin.showsStatistics = false
        
        scnDigitalTwin.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        //Read the connection details from QR code
        oNikarinUtility._CurrentIoTDeviceToWatch = _CurrentIoTDeviceToWatch
        oNikarinUtility.ReadConnectionDetails()
        
        timerReadFromServer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
        
        //Get Tapgesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewControllerTwinLoad.addTwinImageToScene(withGestureRecognizer:)))
        scnDigitalTwin.addGestureRecognizer(tapGestureRecognizer)
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
        
        if _drillBitHolder != nil {
            return
        }
        
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.materials.first?.diffuse.contents = UIColor.gray
        
        let planeNode = SCNNode(geometry: plane)
        
        let x = CGFloat(planeAnchor.center.x)
        //_ = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        planeNode.position = SCNVector3(x,0,z)
        planeNode.opacity = 0.15
        planeNode.eulerAngles.x = -.pi / 2
        
        node.addChildNode(planeNode)
    }
    
    //To read device metrics
    @objc func ReadDisplayValueFromServer() {
        print(" DeviceID : \(oNikarinUtility.oDevID)")
        let DeviceMetrics = oNikarinUtility.GetDeviceMetricsFromServer(anAccessURL: oNikarinUtility.oDevDataUrl, anUserName: oNikarinUtility.oUsrName, anPassword: oNikarinUtility.oPass, bSync: true)
        
        if DeviceMetrics.isEmpty {
            print("Value yet to assign")
            return
        }
        let EmitParamsRes = oNikarinUtility.ReadEmittedParams(anInputStr: DeviceMetrics)
        let DisplayMetrics = EmitParamsRes.anDispMetric
        //print("Metric received \(DisplayMetrics)")
        if (DisplayMetrics == "")
        {
            return
        }
        let iRPM : integer_t = oNikarinUtility.GetRpmValue(stDisplayText: DisplayMetrics)
        ApplyAction(iRPMVal: iRPM)
    }
    
    func ApplyAction(iRPMVal : integer_t) {
        
        if _drillBitHolder == nil {
            return
        }
        
        if iRPMVal > 0 {
            let anloop = SCNAction.repeatForever(SCNAction.rotateBy(x: 1, y: 0, z: 0, duration: 0.1))
            _drillBitHolder?.runAction(anloop)
        }
        else {
            _drillBitHolder?.removeAllActions()
        }
    }
    
    @objc func addTwinImageToScene(withGestureRecognizer recognizer: UIGestureRecognizer) {
        if _drillBitHolder != nil {
            return
        }
        let tapLocation = recognizer.location(in: scnDigitalTwin)
        let hitTestResults = scnDigitalTwin.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        //print ("hittestresults func called")
        guard let hitTestResult = hitTestResults.first else {
            //print ("hittestresults else returned")
            return }
        let translation = hitTestResult.worldTransform.columns.3
        
        guard let twinImgScene = SCNScene(named: "DTwins.scnassets/DrillingMachingTwin.dae"),
            let shipNode = twinImgScene.rootNode.childNode(withName: "SketchUp", recursively: false)
            else {
                //print("ship.scn return")
                return
        }
        //print ("adding node here")
        
        //Drill bit's holder rotation
        _drillBitHolder = twinImgScene.rootNode.childNode(withName: "AnSpinWheelRoot", recursively: true)!
        shipNode.position = SCNVector3(translation.x, translation.y, translation.z)
        scnDigitalTwin.scene.rootNode.addChildNode(shipNode)
    }
    
    @IBAction func CloseView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
