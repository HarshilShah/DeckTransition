//
//  Utilities.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

extension UIView {

    /**
     A function to round selected corners of a `UIView`
    
     - parameter corners: The corner(s) to be rounded
     - parameter radius: The radius of the new rounded corners
    */
    func round(corners: UIRectCorner, withRadius radius: CGFloat) {
        let path = UIBezierPath(
            roundedRect: self.bounds,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }

}
