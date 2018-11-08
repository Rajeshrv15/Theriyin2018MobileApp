//
//  ViewController.swift
//  Nikarin
//
//  Created by Alpha on 16/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit

class ViewController: UIViewController, QRViewControllerDelegate {
    
    var _anQRString : String = "QRText"
    var _loadHuman : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIGraphicsBeginImageContext(self.view.frame.size)
        //UIImage(named: "TileBackground")?.draw(in: self.view.bounds)
        UIImage(named: "ARBackground")?.draw(in: self.view.bounds)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        self.view.backgroundColor = UIColor(patternImage: image)
        // Do any additional setup after loading the view, typically from a nib.
        //self.view.backgroundColor = UIColor(patternImage: UIImage(named: "FotoliaBackground")!)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func onReadDeviceData(_ sender: UIButton) {
        performSegue(withIdentifier: "AnShowDeviceData", sender: self)
    }
        
    @IBAction func onLoadQRReader(_ sender: UIButton) {
        performSegue(withIdentifier: "AnShowQRReader", sender: self)
    }
    
    @IBAction func onLoadDigitalTwin(_ sender: UIButton) {
        _loadHuman = false
        performSegue(withIdentifier: "AnShowDigitalTwin", sender: self)
    }
    
    @IBAction func onLoadCollab(_ sender: UIButton) {
        performSegue(withIdentifier: "AnShowCollab", sender: self)
    }
    
    @IBAction func onLoadTwinAnimation(_ sender: UIButton) {
        performSegue(withIdentifier: "AnShowDigitalTwinTraining", sender: self)
    }
    
    @IBAction func onLoadHumanTwin(_ sender: UIButton) {
        _loadHuman = true
        performSegue(withIdentifier: "AnShowDigitalTwin", sender: self)
    }
    
    
    func finishPassing(string: String) {
        self._anQRString = string
        //print("Received from QR Reader : " + self._anQRString)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destination = segue.destination as? QRViewController {
            destination.delegate = self
        }
        if (segue.identifier == "AnShowDeviceData")  {
            guard let destinationVC = segue.destination as? ARScenekitViewController else {
                //print("Nee neikiera sender nan illai " + segue.debugDescription)
                return
            }
            destinationVC._CurrentIoTDeviceToWatch = self._anQRString
        }
        if (segue.identifier == "AnShowDigitalTwin" )  {
            guard let destinationVC = segue.destination as? ViewControllerTwinLoad else {
                //print("Nee neikiera sender nan illai " + segue.debugDescription)
                return
            }
            destinationVC._CurrentIoTDeviceToWatch = self._anQRString
            destinationVC._LoadHumanTwin = self._loadHuman
        }
        
    }
    
}

