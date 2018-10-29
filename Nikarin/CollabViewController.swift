//
//  CollabViewController.swift
//  Nikarin
//
//  Created by Alpha on 29/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit
import ARKit
import SceneKit

class CollabViewController: UIViewController, ARSCNViewDelegate {
    
    
    @IBOutlet weak var scnViewCollab: ARSCNView!
    
    @IBAction func btnClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
