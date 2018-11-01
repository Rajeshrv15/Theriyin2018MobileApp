//
//  ARScenekitViewController.swift
//  ARSceneView_QRReadder
//
//  Created by Alpha on 03/08/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import Foundation
import MBProgressHUD

class ARScenekitViewController: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet weak var anSceneView: ARSCNView!
    
    //Current Device ID & end point details
    var oNikarinUtility: NikarinUtility = NikarinUtility()
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    
    //Sceen Text to show _DeviceMetrics
    var _ParentNodeForTextNode : SCNNode!
    var _ParentNodeAnchor : ARObjectAnchor!
    var _DeviceMetrics : String = ""
    var _NewLocationSCNVector3 : SCNVector3!
    var textNode = SCNNode()
    let configuration = ARWorldTrackingConfiguration()
    var _sDisplayMetrics : String!
    var _sDisplayMessage : String!
    
    //timer controller to refresh page
    var _timerCount : Int = 0
    var timerReadFromServer: Timer!
    var timerUpdateTextNode: Timer!
    
    var _oUserHUD: MBProgressHUD!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // Set the view's delegate
        anSceneView.delegate = self
        
        // Show statistics such as fps and timing information
        anSceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        anSceneView.scene = scene
        
        self.anSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]//, ARSCNDebugOptions.showWorldOrigin]
        self.anSceneView.showsStatistics = false
        //self.anSceneView.session.run(configuration)
        self.anSceneView.delegate = self
        
        //Read the connection details from QR code
        oNikarinUtility._CurrentIoTDeviceToWatch = _CurrentIoTDeviceToWatch
        oNikarinUtility.ReadConnectionDetails()
        
        timerReadFromServer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(ReadDisplayValueFromServer), userInfo: nil, repeats: true)
        timerUpdateTextNode = Timer.scheduledTimer(timeInterval: 3, target: self, selector: #selector(UpdateTextNode), userInfo: nil, repeats: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if #available(iOS 12.0, *) {
            guard let anRefCalendarObject = ARReferenceObject.referenceObjects(inGroupNamed: "anARResources", bundle: nil) else {
                print("Unable to load resource")
                return
            }
            configuration.detectionObjects = anRefCalendarObject
            self.anSceneView.session.run(configuration)
            print("Object resource loaded...")
        } else {
            // Fallback on earlier versions
        }        
    }
    
    @IBAction func TriggerPrediction(_ sender: UIButton) {
        sender.press(completion:{ finish in
            if finish {
                print("animation ended - TriggerPrediction")
            }
        })
        let sZemantisURL : String = "http://10.60.5.238:9083/adapars/apply/drill_pmml?record={\"RPM\": 2350,\"Temperature\": 52,\"Sound\": 3.2}"
        let strZemantisResDict = oNikarinUtility.GetDeviceMetricsFromServer(anAccessURL: sZemantisURL, anUserName: "Administrator", anPassword: "manage", bSync: true)
        print("Response received \(strZemantisResDict)")
        let sUIVal = oNikarinUtility.ReadValueFromDictionaryWithKey(dtInput: strZemantisResDict, stKey: "predicted_Maintenance")
        ShowProgressMessage(anuserHUDmessage: "As per prediction maintenance required. \(sUIVal)", anTimeInterval: TimeInterval(5))
    }
    
    @IBAction func TriggerBPMN(_ sender: UIButton) {
        sender.press(completion:{ finish in
            if finish {
                print("animation ended - TriggerBPMN")
            }
        })
        let sBPMSURL : String = "http://10.60.5.238:5555/invoke/Service/CallRepairBPMS?DeviceID=2323456&DeviceName=Drill&Email=\(oNikarinUtility.oEmailIds)&EmailBody=Send Technician for the service"
        let strBPMSResDict = oNikarinUtility.GetDeviceMetricsFromServer(anAccessURL: sBPMSURL, anUserName: "Administrator", anPassword: "manage", bSync: true)
        ShowProgressMessage(anuserHUDmessage: "BPMS triggered.", anTimeInterval: TimeInterval(5))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        anSceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if #available(iOS 12.0, *) {
            if anchor is ARObjectAnchor {                
                ShowProgressMessage(anuserHUDmessage: "Scanned object \(String(describing: anchor.name)) detected...", anTimeInterval: TimeInterval(1))
                _ParentNodeForTextNode = node
                _ParentNodeAnchor = anchor as? ARObjectAnchor
            }
        } else {
            print ("Scan object not detected")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let currentTouchPoint = touches.first?.location(in: anSceneView) else { return }
        
        let result = anSceneView.hitTest(currentTouchPoint, options: nil)
        
        if let hitResult = result.first{
            
            let newPosition2 = hitResult.localCoordinates
            
            if let tappedNode = result.first?.node {
                //tappedNode.position = SCNVector3Make(tappedNode.position.x+newPosition2.x, tappedNode.position.y+newPosition2.y, tappedNode.position.z)
                _NewLocationSCNVector3 = SCNVector3Make(tappedNode.position.x+newPosition2.x, tappedNode.position.y+newPosition2.y, tappedNode.position.z)
            }
        }
    }
    
    
    @IBAction func OnCloseClick(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    //To read device metrics
    @objc func ReadDisplayValueFromServer() {
        _timerCount = _timerCount + 1
        //print("Current timer count  \(_timerCount)")
        print(" DeviceID : \(oNikarinUtility.oDevID)")
        /*print(" DeviceDataUrl : \(oDevDataUrl)")
         print(" UserName : \(oUsrName)")
         print(" Password : \(oPass)")
         print(" Previous Response : \(self._DeviceMetrics)")*/
        self._DeviceMetrics = oNikarinUtility.GetDeviceMetricsFromServer(anAccessURL: oNikarinUtility.oDevDataUrl, anUserName: oNikarinUtility.oUsrName, anPassword: oNikarinUtility.oPass, bSync: true)
        
        if _DeviceMetrics.isEmpty {
            print("Value yet to assign")
            return
        }
        var EmitParamsRes = oNikarinUtility.ReadEmittedParams(anInputStr: _DeviceMetrics)
        _sDisplayMessage = EmitParamsRes.anDispMsg
        _sDisplayMetrics = EmitParamsRes.anDispMetric
        
        if (_sDisplayMetrics == "")
        {
            //_sDisplayMetrics = "Temperature:\(_timerCount),Speed:\(3429 + _timerCount),Sound:\(0.88 + Double(_timerCount))"
            _sDisplayMetrics = "Sound:\(_timerCount),Vibration:\(12 + _timerCount),Smoke:\(88 + Double(_timerCount))"
        }
        /*if (_sDisplayMessage == "")
        {
            _sDisplayMessage = "Temperature execeeded the threshold."// coming from Nikarin platform based on the scanned device"
        }*/
    }
    
    @objc func UpdateTextNode() {
        if _ParentNodeForTextNode == nil {
            return
        }
        if _sDisplayMetrics == nil {
            return
        }
        
        if _ParentNodeForTextNode != nil && _ParentNodeForTextNode.childNodes.count > 0 {
            _ParentNodeForTextNode.childNodes .forEach { item in
                item.removeFromParentNode()
            }
        }
        
        let lstSCNNodes = GetIndividualSpiteTextNode(stDisplayText: self._sDisplayMetrics)
        if lstSCNNodes.count == 0 {
            return
        }
        
        var iYPosition = 0.1
        lstSCNNodes .forEach { item in
            if _NewLocationSCNVector3 != nil {
                item.position = _NewLocationSCNVector3
            }
            else {
                item.position = SCNVector3(_ParentNodeAnchor.transform.columns.3.x, Float(iYPosition), _ParentNodeAnchor.transform.columns.3.z)
            }
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
            
            let dispStr = GetParamSpriteNode(strParamType: String(item), Circle: Circle)
            
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
            let textNode = GetDisplayMessageNode(skScene: skScene)
            skScene.addChild(textNode)
        }
        
        let plane = SCNPlane(width: CGFloat(0.4), height: CGFloat(0.2))
        plane.firstMaterial!.diffuse.contents = skScene
        let finalDisplayNode = SCNNode(geometry: plane)
        lstSCNodesText.append(finalDisplayNode)
        
        return lstSCNodesText
    }
    
    func GetParamSpriteNode(strParamType: String, Circle: SKShapeNode) -> String {
        var sRetString : String = strParamType
        if strParamType.range(of: "Temperature") != nil {
            let temperature = GetScnNodeWithImage(stImageName: "temperature-2-64_white", stScaleVal: 2.0)
            Circle.addChild(temperature)
            let sTmpRetString = oNikarinUtility.GetSplitStringValue(stInput: strParamType)
            sRetString = "\(sTmpRetString)'C"
        }
        if strParamType.range(of: "Speed") != nil {
            let speed = GetScnNodeWithImage(stImageName: "speedometer-32", stScaleVal: 3.5)
            Circle.addChild(speed)
            sRetString = oNikarinUtility.GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Sound") != nil {
            let sound = GetScnNodeWithImage(stImageName: "speaker-32", stScaleVal: 3.0)
            Circle.addChild(sound)
            sRetString = oNikarinUtility.GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Smoke") != nil {
            let smoke = GetScnNodeWithImage(stImageName: "Smoke-32-white", stScaleVal: 3.5)
            Circle.addChild(smoke)
            sRetString = oNikarinUtility.GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Vibration") != nil {
            let vibration = GetScnNodeWithImage(stImageName: "Vibration-32-white", stScaleVal: 3.0)
            Circle.addChild(vibration)
            sRetString = oNikarinUtility.GetSplitStringValue(stInput: strParamType)
        }
        return sRetString
    }
    
    func GetScnNodeWithImage(stImageName: String, stScaleVal: CGFloat) -> SKSpriteNode {
        let skDisplayNode = SKSpriteNode(imageNamed: stImageName)
        skDisplayNode.position = CGPoint(x: 90, y: 8)
        skDisplayNode.setScale(stScaleVal)
        return skDisplayNode
    }
    
    func GetDisplayMessageNode(skScene : SKScene) -> SKSpriteNode {
        let iYPosition = 250
        let box = SKSpriteNode(color: UIColor.clear, size: CGSize(width: 1900, height: 450))
        
        //to show in row        
        //box.position = CGPoint(x: skScene.frame.minX + CGFloat(355) , y: skScene.frame.minY + (box.size.height/2) + CGFloat(iYPosition))
        box.position = CGPoint(x: 0 , y: skScene.frame.minY + (box.size.height/2) + CGFloat(iYPosition))
        //to show in column
        //box.position = CGPoint(x: CGFloat(iXPosition), y: skScene.frame.minY + (box.size.height/2))
        //box.position = CGPoint(x: CGFloat(iXPosition), y: skScene.frame.minY + CGFloat(25))
        box.yScale=box.yScale * -1
        //box.anchorPoint = CGPoint(x:0, y: 0.5)
        
        let label = SKLabelNode(fontNamed:"ArialMT")
        label.text = String(_sDisplayMessage)
        label.position = CGPoint(x: box.position.x + CGFloat(850), y: -72)
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 1500
        //label.horizontalAlignmentMode = .left
        //label.verticalAlignmentMode = .center
        label.fontSize =  80
        label.fontColor = UIColor.black
        
        let f0 = SKTexture.init(imageNamed: "alert-64")
        let f1 = SKTexture.init(imageNamed: "alert-blank")
        let f2 = SKTexture.init(imageNamed: "alert-64")
        let frames: [SKTexture] = [f0, f1, f2]
        
        let alertIcon = SKSpriteNode(imageNamed: "alert-64")
        alertIcon.position = CGPoint(x: -box.position.x + CGFloat(72) , y:0)
        alertIcon.setScale(2)
        
        // Change the frame per 0.2 sec
        let animation = SKAction.animate(with: frames, timePerFrame: 0.2)
        alertIcon.run(SKAction.repeatForever(animation))
        
        box.addChild(alertIcon)
        box.addChild(label)
        
        return box
    }
    
    func ShowProgressMessage(anuserHUDmessage: String, anTimeInterval: TimeInterval) {
        DispatchQueue.main.async {
            self._oUserHUD = MBProgressHUD.showAdded(to: self.view, animated: true)
            self._oUserHUD.label.text = anuserHUDmessage
            self._oUserHUD.hide(animated: true, afterDelay: anTimeInterval)
        }
    }
}

struct IoTDeviceData {
    let DeviceID: String
    let DeviceIoTHub: String
    let DeviceEmittingParams: String
    let DeviceEmittingMessage: String
}

func + (left: SCNVector3, right:SCNVector3) -> SCNVector3 {
    return SCNVector3Make(left.x+right.x, left.y+right.y, left.z+right.z)
}
