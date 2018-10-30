//
//  JsonReaderUtility.swift
//  Nikarin
//
//  Created by Alpha on 30/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import Foundation

class JsonReaderUtility {
    
    public var _CurrentIoTDeviceToWatch : String = "CodedDeviceId"
    public var oDevID : String = ""
    public var oDevDataUrl : String = ""
    public var oUsrName : String = ""
    public var oPass : String = ""
    public var oEmailIds : String = ""
    
    //To read the connectivity details from QR code response
    func ReadConnectionDetails() {
        var dictionary:NSDictionary?
        print(_CurrentIoTDeviceToWatch)
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
    
}
