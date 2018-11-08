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
    public var _LoadHumanTwin : Bool = false
    
    var timerReadFromServer: Timer!
    var timerUpdateTextNode: Timer!
    
    var _twinTranslationlocation: simd_float4!
    var _ParentNodeForTextNode : SCNNode!
    var _sDisplayMetrics : String!
    var _sDisplayMessage : String!
    
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
        
        timerReadFromServer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
        timerUpdateTextNode = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateTextNode), userInfo: nil, repeats: true)
        
        //Get Tapgesture
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewControllerTwinLoad.addTwinImageToScene(withGestureRecognizer:)))
        scnDigitalTwin.addGestureRecognizer(tapGestureRecognizer)
        
        //Setup lightings 
        setupAmbientLight()
        setupOmniDirectionalLight()
        
        print("Current view to load _LoadHumanTwin \(_LoadHumanTwin))")
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
    
    @objc func UpdateTextNode() {
        if _ParentNodeForTextNode == nil {
            return
        }
        if _sDisplayMetrics == nil {
            print("i am returning")
            return
        }
        
        if _ParentNodeForTextNode != nil && _ParentNodeForTextNode.childNodes.count > 0 {
            _ParentNodeForTextNode.childNodes .forEach { item in
                if item.name == "anSCNTextNodes" {
                    item.removeFromParentNode()
                }
            }
        }
        
        let lstSCNNodes = GetIndividualSpiteTextNode(stDisplayText: self._sDisplayMetrics)
        if lstSCNNodes.count == 0 {
            return
        }
        
        var iYPosition = 0.0
        lstSCNNodes .forEach { item in
            item.position = SCNVector3(_twinTranslationlocation.x, Float(iYPosition), _twinTranslationlocation.z - Float(0.1))
            item.name = "anSCNTextNodes"
            _ParentNodeForTextNode.addChildNode(item)
            iYPosition = iYPosition + 0.015
        }

    }
    
    func GetIndividualSpiteTextNode(stDisplayText: String) -> Array<SCNNode> {
        
        var lstSCNodesText = [SCNNode()]
        let splitTextArray = stDisplayText.split(separator: ",")
        
        var iXPosition = CGFloat(5)
        
        let skScene = SKScene(size:CGSize(width: 1600, height: 800))
        skScene.scaleMode = .aspectFit
        skScene.shouldEnableEffects = true
        skScene.backgroundColor = UIColor.clear
        skScene.blendMode = .alpha
        
        splitTextArray.forEach { item in
            iXPosition = iXPosition + skScene.frame.minX + CGFloat(350)
            
            let Circle = SKShapeNode(circleOfRadius: 150 ) // Size of Circle = Radius setting.
            Circle.position = CGPoint(x:iXPosition,y:200)
            Circle.name = "defaultCircle"
            Circle.strokeColor = UIColor.black
            Circle.glowWidth = 1.0
            Circle.fillColor = UIColor.black
            Circle.yScale=Circle.yScale * -1
            
            let dispStr = oNikarinUtility.GetParamSpriteNode(strParamType: String(item), Circle: Circle)
            
            let label = SKLabelNode(fontNamed:"ArialMT")
            label.text = String(dispStr)
            label.position = CGPoint(x: 18, y: 0)
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .center
            label.fontSize =  72
            label.fontColor = UIColor.white
            
            /*box.addChild(label)
             skScene.addChild(box)*/
            
            Circle.addChild(label)
            skScene.addChild(Circle)
            
            //iYPosition = iYPosition + 100
        }
        
        if _sDisplayMessage != nil && _sDisplayMessage != ""{
            let textNode = oNikarinUtility.GetDisplayMessageNode(skScene: skScene, sDisplayMessage: _sDisplayMessage)
            skScene.addChild(textNode)
        }
        
        let plane = SCNPlane(width: CGFloat(0.4), height: CGFloat(0.2))
        plane.firstMaterial!.diffuse.contents = skScene
        let finalDisplayNode = SCNNode(geometry: plane)
        lstSCNodesText.append(finalDisplayNode)
        
        return lstSCNodesText
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
        _sDisplayMetrics = EmitParamsRes.anDispMetric
        _sDisplayMessage = EmitParamsRes.anDispMsg
        //print("Metric received \(DisplayMetrics)")
        if (_sDisplayMetrics == "")
        {
            return
        }
        let iRPM : integer_t = oNikarinUtility.GetRpmValue(stDisplayText: _sDisplayMetrics)
        ApplyAction(iRPMVal: iRPM)
        
        /*if (_sDisplayMessage == "")
        {
            _sDisplayMessage = "Temperature execeeded the threshold."// coming from Nikarin platform based on the scanned device"
        }*/
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
        _twinTranslationlocation = hitTestResult.worldTransform.columns.3
        
        guard let twinImgScene = SCNScene(named: "DTwins.scnassets/DrillingMachingTwin.dae"),
            let shipNode = twinImgScene.rootNode.childNode(withName: "SketchUp", recursively: false)
            else {
                //print("ship.scn return")
                return
        }
        //print ("adding node here")
        
        //Drill bit's holder rotation
        _drillBitHolder = twinImgScene.rootNode.childNode(withName: "AnSpinWheelRoot", recursively: true)!
        shipNode.position = SCNVector3(_twinTranslationlocation.x, _twinTranslationlocation.y, _twinTranslationlocation.z)
        scnDigitalTwin.scene.rootNode.addChildNode(shipNode)
        _ParentNodeForTextNode = scnDigitalTwin.scene.rootNode
    }
    
    private func setupAmbientLight() {
        // setup ambient light source
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = UIColor(white: 0.53, alpha: 1.0).cgColor
        scnDigitalTwin.scene.rootNode.addChildNode(ambientLightNode)
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
        scnDigitalTwin.scene.rootNode.addChildNode(omniLightNode)
    }
    
    @IBAction func CloseView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
