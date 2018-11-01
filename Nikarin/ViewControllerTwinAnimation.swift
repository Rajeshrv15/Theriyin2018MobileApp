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
    
    
    @IBAction func clickRefresh(_ sender: UIButton) {
    }
    
    @IBAction func clickNextStep(_ sender: UIButton) {
    }    
    
    @IBAction func clickClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
}
