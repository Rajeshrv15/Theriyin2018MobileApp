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

class ViewControllerTwinLoad: UIViewController {
    
    
    @IBOutlet weak var scnDigitalTwin: ARSCNView!
    
    @IBAction func CloseView(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}
