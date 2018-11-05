//
//  ButtonDesigner.swift
//  Nikarin
//
//  Created by Alpha on 29/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit

@IBDesignable
class RoundedButton: UIButton {
    
    /*override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }*/
    
    /*required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }*/
    
    /*func setup() {
        backgroundColor = tintColor
        layer.cornerRadius = 8
        clipsToBounds = true
        setTitleColor(.white, for: [])
        titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
    }*/
    
    override var isEnabled: Bool {
        didSet {            
            backgroundColor = isEnabled ? tintColor : .gray
            //alpha = isEnabled ? 1.0 : 0.5
            //setBackgroundImage(UIImage(named: "GotoArrow"), for: UIControl.State.normal)
            showsTouchWhenHighlighted = true
        }
    }
}

extension UIButton {
    func press(completion:@escaping ((Bool) -> Void)) {
        UIView.animate(withDuration: 0.8, animations: {
            self.transform = CGAffineTransform(scaleX: 0.5, y: 0.5) }, completion: { (finish: Bool) in
                UIView.animate(withDuration: 0.5, animations: {
                    //self.imageView?.alpha = 0.1
                    //self.imageView?.backgroundColor = UIColor.green
                    self.transform = CGAffineTransform.init(rotationAngle: CGFloat.pi)
                    //self.tintColor = UIColor.red
                    self.transform = CGAffineTransform.identity
                    completion(finish)
                })
        })
    }
}
