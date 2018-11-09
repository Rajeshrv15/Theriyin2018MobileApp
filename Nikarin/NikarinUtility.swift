//
//  JsonReaderUtility.swift
//  Nikarin
//
//  Created by Alpha on 30/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class NikarinUtility {
    
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    public var oDevID : String = ""
    public var oDevDataUrl : String = ""
    public var oUsrName : String = ""
    public var oPass : String = ""
    public var oEmailIds : String = ""
    public var oAlarmClearURL : String = ""
    
    //To read the connectivity details from QR code response
    func ReadConnectionDetails() {
        var dictionary:NSDictionary?
        print("Received Device Identity : \(_CurrentIoTDeviceToWatch)")
        if let data = _CurrentIoTDeviceToWatch.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    oDevID = ReadContentString(dictInput: myDictionary, dictKey: "DeviceID")
                    oDevDataUrl = ReadContentString(dictInput: myDictionary, dictKey: "DeviceDataUrl")
                    oUsrName = ReadContentString(dictInput: myDictionary, dictKey: "UserName")
                    oPass = ReadContentString(dictInput: myDictionary, dictKey: "Password")
                    oEmailIds = ReadContentString(dictInput: myDictionary, dictKey: "MailIds")
                    oAlarmClearURL = ReadContentString(dictInput: myDictionary, dictKey: "AlarmUrl")
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
    
    func ReadValueFromDictionaryWithKey(dtInput : String, stKey : String) -> String {
        
        var stOutput : String = ""
        if dtInput.isEmpty {
            return stOutput
        }
        var dictionary:NSDictionary?
        if let data = dtInput.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
            } catch {
                return ""
            }
            if let myDictionary = dictionary {
                for (_, anValue) in myDictionary {
                    if anValue is NSArray {
                        let temp = anValue as AnyObject as! NSArray
                        if temp != nil {
                            //print ("am with array now !")
                            temp.forEach { anitem in
                                let anDict:NSDictionary = (anitem as! [String:AnyObject] as NSDictionary?)!
                                if anDict != nil {
                                    for(_, _) in anDict {
                                        let anOutput = anDict.value(forKey: stKey) as? String
                                        if (anOutput != nil) {
                                            stOutput = anOutput!
                                        }
                                    }
                                }
                            }
                        }
                    }
                    else
                    {
                        let anOutput = myDictionary.value(forKey: stKey) as? String
                        if (anOutput != nil) {
                            stOutput = anOutput!
                        }
                    }
                }
            }
            
            /*do {
             dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
             if let myDictionary = dictionary
             {
             let anOutput = myDictionary.value(forKey: stKey) as? String
             if (anOutput != nil) {
             stOutput = anOutput!
             }
             }
             } catch let error as NSError {
             print(error)
             }*/
        }
        return stOutput
    }
    
    func ReadEmittedParams(anInputStr : String) -> (anDispMetric : String, anDispMsg : String) {
        var dictionary:NSDictionary?
        var sDisplayMetrics = ""
        var sDisplayMessage = ""
        if let data = anInputStr.data(using: String.Encoding.utf8) {
            do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                if let myDictionary = dictionary
                {
                    //print("DeviceID : \(myDictionary["DeviceID"] ?? "default DeviceID")")
                    var anEmitParam = myDictionary.value(forKey: "DeviceEmittingParams") as? String
                    if (anEmitParam != nil) {
                        //print("DeviceEmittingParams 1 : \(self._sDisplayMessage)")
                        //anEmitParam = "de1 \(_timerCount),de2 \(_timerCount),de3 \(_timerCount),de4 \(_timerCount)"
                        sDisplayMetrics = anEmitParam!
                    }
                    anEmitParam = myDictionary.value(forKey: "DeviceEmittingMessage") as? String
                    if (anEmitParam != nil) {
                        //print("DeviceEmittingParams 1 : \(self._sDisplayMessage)")
                        //anEmitParam = "de1 \(_timerCount),de2 \(_timerCount),de3 \(_timerCount),de4 \(_timerCount)"
                        sDisplayMessage = anEmitParam!
                    }
                    //print("DeviceEmittingParams 2 : \(self._sDisplayMessage)")
                }
            } catch let error as NSError {
                print(error)
            }
        }
        return (sDisplayMetrics, sDisplayMessage)
    }
    
    func GetSplitStringValue(stInput: String) -> String {
        let splitTextArray = stInput.split(separator: ":")
        let sRetString : String = String(splitTextArray[1])
        return sRetString
    }
    
    func GetRpmValue(stDisplayText : String) -> integer_t {
        var sRetString : String = ""
        var iRpm : integer_t = 0
        let splitTextArray = stDisplayText.split(separator: ",")
        splitTextArray.forEach { item in
            if item.range(of: "Speed") != nil {
                sRetString = GetSplitStringValue(stInput: String(item))
            }
        }
        //print(sRetString)
        iRpm = integer_t(sRetString) ?? 0
        return iRpm
    }
    
    //Read device metrics from Server URL
    func GetDeviceMetricsFromServer(anAccessURL : String, anUserName: String, anPassword: String, bSync: Bool) -> String {
        let config = URLSessionConfiguration.default
        var strResponse : String = ""
        let anSem = DispatchSemaphore.init(value: 0)
        
        if (anAccessURL == nil || anAccessURL.isEmpty) {
            return strResponse
        }
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        //print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        let anUrl = URL(string: anAccessURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        let anDataTsk = session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            anResponse = String(data: data!, encoding: .utf8)!
            strResponse = anResponse
            if bSync == true {
                anSem.signal()
            }
            //self._DeviceMetrics = anResponse
        })
        anDataTsk.resume()
        if bSync == true {
            anSem.wait(timeout: .distantFuture)
        }
        //print("And I got this reponse : \(strResponse))")
        return strResponse
    }
    
    //Send request for creating case in AgileApps
    func PostDeviceMetricsFromServer(anAccessURL : String, anUserName: String, anPassword: String, anBodyContent: String, bSync: Bool) -> String {
        let config = URLSessionConfiguration.default
        var strResponse : String = ""
        let anSem = DispatchSemaphore.init(value: 0)
        
        if (anAccessURL == nil || anAccessURL.isEmpty) {
            return strResponse
        }
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        //print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        let anUrl = URL(string: anAccessURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        var anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        
        anUrlRequest.httpMethod = "POST"
        let bodyString : String = anBodyContent
        let bodyData = bodyString.data(using: String.Encoding.utf8)
        anUrlRequest.httpBody = bodyData
        anUrlRequest.setValue("application/xml", forHTTPHeaderField: "Content-Type")
        
        let anDataTsk = session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            anResponse = String(data: data!, encoding: .utf8)!
            strResponse = anResponse
            if bSync == true {
                anSem.signal()
            }
        })
        anDataTsk.resume()
        if bSync == true {
            anSem.wait(timeout: .distantFuture)
        }
        //print("POST I got this reponse : \(strResponse))")
        return strResponse
    }
    
    func GetParamSpriteNode(strParamType: String, Circle: SKShapeNode) -> String {
        var sRetString : String = strParamType
        if strParamType.range(of: "Temperature") != nil {
            let temperature = GetScnNodeWithImage(stImageName: "temperature-2-64_white", stScaleVal: 2.0)
            Circle.addChild(temperature)
            let sTmpRetString = GetSplitStringValue(stInput: strParamType)
            sRetString = "\(sTmpRetString)'C"
        }
        if strParamType.range(of: "Speed") != nil {
            let speed = GetScnNodeWithImage(stImageName: "speedometer-32", stScaleVal: 3.5)
            Circle.addChild(speed)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Sound") != nil {
            let sound = GetScnNodeWithImage(stImageName: "speaker-32", stScaleVal: 3.0)
            Circle.addChild(sound)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Smoke") != nil {
            let smoke = GetScnNodeWithImage(stImageName: "Smoke-32-white", stScaleVal: 3.5)
            Circle.addChild(smoke)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        if strParamType.range(of: "Vibration") != nil {
            let vibration = GetScnNodeWithImage(stImageName: "Vibration-32-white", stScaleVal: 3.0)
            Circle.addChild(vibration)
            sRetString = GetSplitStringValue(stInput: strParamType)
        }
        return sRetString
    }
    
    func GetScnNodeWithImage(stImageName: String, stScaleVal: CGFloat) -> SKSpriteNode {
        let skDisplayNode = SKSpriteNode(imageNamed: stImageName)
        skDisplayNode.position = CGPoint(x: 90, y: 8)
        skDisplayNode.setScale(stScaleVal)
        return skDisplayNode
    }
    
    func GetDisplayMessageNode(skScene : SKScene, sDisplayMessage: String) -> SKSpriteNode {
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
        label.text = String(sDisplayMessage)
        label.position = CGPoint(x: box.position.x + CGFloat(850), y: -72)
        label.numberOfLines = 2
        label.preferredMaxLayoutWidth = 1500
        //label.horizontalAlignmentMode = .left
        //label.verticalAlignmentMode = .center
        label.fontSize =  80
        label.fontColor = UIColor.red
        
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
}
