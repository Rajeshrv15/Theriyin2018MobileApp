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

class ARScenekitViewController: UIViewController, ARSCNViewDelegate, QRViewControllerDelegate {
    
    
    @IBOutlet weak var anSceneView: ARSCNView!
    
    //Current Device ID & end point details
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    var oDevID : String = ""
    var oDevDataUrl : String = ""
    var oUsrName : String = ""
    var oPass : String = ""
    
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
        
        //self.anSceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints, ARSCNDebugOptions.showWorldOrigin]
        self.anSceneView.showsStatistics = true
        //self.anSceneView.session.run(configuration)
        self.anSceneView.delegate = self
        
        
        ReadConnectionDetails() //Read the connection details from QR code
        
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
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        anSceneView.session.pause()
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        if #available(iOS 12.0, *) {
            if anchor is ARObjectAnchor {
                //print ("Object detected \(node)")
                ShowProgressMessage(anuserHUDmessage: "Scanned object detected...", anTimeInterval: TimeInterval(1))
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
    
    func finishPassing(string: String) {
        //ShowProgressMessage(anuserHUDmessage: "QR reading completed", anTimeInterval: TimeInterval(2))
        _CurrentIoTDeviceToWatch = string
    }
    
    //To read the connectivity details from QR code response
    func ReadConnectionDetails() {
        var dictionary:NSDictionary?
        if let data = _CurrentIoTDeviceToWatch.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    oDevID = ReadContentString(dictInput: myDictionary, dictKey: "DeviceID")
                    oDevDataUrl = ReadContentString(dictInput: myDictionary, dictKey: "DeviceDataUrl")
                    oUsrName = ReadContentString(dictInput: myDictionary, dictKey: "UserName")
                    oPass = ReadContentString(dictInput: myDictionary, dictKey: "Password")
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func ReadContentString(dictInput: NSDictionary, dictKey: String) -> String {
        var oResStr = "NA"
        let anEmitParam = dictInput.value(forKey: dictKey) as? String
        if (anEmitParam != nil) {
            oResStr = anEmitParam!
        }
        return oResStr;
    }
    
    //To read device metrics
    @objc func ReadDisplayValueFromServer() {
        _timerCount = _timerCount + 1
        print("Current timer count  \(_timerCount)")
        print(" DeviceID : \(oDevID)")
        /*print(" DeviceDataUrl : \(oDevDataUrl)")
         print(" UserName : \(oUsrName)")
         print(" Password : \(oPass)")
         print(" Previous Response : \(self._DeviceMetrics)")*/
        GetDeviceMetricsFromServer(anAccessURL: oDevDataUrl, anUserName: oUsrName, anPassword: oPass)
        
        if _DeviceMetrics.isEmpty {
            //print("Value yet to assign")
            return
        }
        var dictionary:NSDictionary?
        _sDisplayMetrics = ""
        _sDisplayMessage = ""
        if let data = _DeviceMetrics.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    //print("DeviceID : \(myDictionary["DeviceID"] ?? "default DeviceID")")
                    var anEmitParam = myDictionary.value(forKey: "DeviceEmittingParams") as? String
                    if (anEmitParam != nil) {
                        //print("DeviceEmittingParams 1 : \(self._sDisplayMessage)")
                        //anEmitParam = "de1 \(_timerCount),de2 \(_timerCount),de3 \(_timerCount),de4 \(_timerCount)"
                        self._sDisplayMetrics = anEmitParam!
                    }
                    anEmitParam = myDictionary.value(forKey: "DeviceEmittingMessage") as? String
                    if (anEmitParam != nil) {
                        //print("DeviceEmittingParams 1 : \(self._sDisplayMessage)")
                        //anEmitParam = "de1 \(_timerCount),de2 \(_timerCount),de3 \(_timerCount),de4 \(_timerCount)"
                        self._sDisplayMessage = anEmitParam!
                    }
                    //print("DeviceEmittingParams 2 : \(self._sDisplayMessage)")
                }
            } catch let error as NSError {
                print(error)
            }
        }
        
        if (_sDisplayMetrics == "")
        {
            _sDisplayMetrics = "temperature:\(_timerCount)'C,rpm:\(3429 + _timerCount),loudness:\(0.88 + Double(_timerCount))"
        }
        if (_sDisplayMessage == "")
        {
            _sDisplayMessage = "Temperature execeeded the threshold."// coming from Nikarin platform based on the scanned device"
        }
    }
    
    //Read device metrics from Server URL
    func GetDeviceMetricsFromServer(anAccessURL : String, anUserName: String, anPassword: String ) {
        let config = URLSessionConfiguration.default
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        //print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        let anUrl = URL(string: anAccessURL)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            anResponse = String(data: data!, encoding: .utf8)!
            self._DeviceMetrics = anResponse
        }).resume()
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
        if strParamType.range(of: "temperature") != nil {
            let temperature = SKSpriteNode(imageNamed: "temperature-2-64_white")
            temperature.position = CGPoint(x: 90, y: 8)
            temperature.setScale(2)
            Circle.addChild(temperature)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "rpm") != nil {
            let temperature = SKSpriteNode(imageNamed: "speedometer-32")
            temperature.position = CGPoint(x: 90, y: 8)
            temperature.setScale(3.5)
            Circle.addChild(temperature)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "loudness") != nil {
            let temperature = SKSpriteNode(imageNamed: "speaker-32")
            temperature.position = CGPoint(x: 90, y: 8)
            temperature.setScale(3)
            Circle.addChild(temperature)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }        
        return sRetString
    }
    
    func GetSplitStringValue(stInput: String) -> String {
        let splitTextArray = stInput.split(separator: ":")
        let sRetString : String = String(splitTextArray[1])
        return sRetString
    }
    
    func GetDisplayMessageNode(skScene : SKScene) -> SKSpriteNode {
        let iYPosition = 400
        let box = SKSpriteNode(color: UIColor.yellow, size: CGSize(width: 1900, height: 450))
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
        label.position = CGPoint(x: box.position.x + CGFloat(720), y: 1)
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 1500
        //label.horizontalAlignmentMode = .left
        //label.verticalAlignmentMode = .center
        label.fontSize =  70
        label.fontColor = UIColor.black
        
        let alertIcon = SKSpriteNode(imageNamed: "alert-64")
        alertIcon.position = CGPoint(x: -box.position.x + CGFloat(72) , y:0)
        alertIcon.setScale(2)
        
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
