//
//  RoundedView.swift
//  DeckTransition
//
//  Created by Harshil Shah on 05/08/17.
//  Copyright © 2017 Harshil Shah. All rights reserved.
//

import UIKit

final class RoundedView: UIView {
    
    // MARK:- Public variables
    
    public var cornerRadius = Constants.cornerRadius {
        didSet {
            updateMaskPath()
        }
    }
    
    // MARK:- Private variables
    
    private let maskLayer = CAShapeLayer()
    
    // MARK:- Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        backgroundColor = .black
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.fillRule = kCAFillRuleEvenOdd
        layer.mask = maskLayer
    }
    
    // MARK:- View lifecycle methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        maskLayer.frame = bounds
        updateMaskPath()
    }
    
    private func updateMaskPath() {
        /// The height is a bit higher than the rounded view to accomodate for
        /// a black line that flickers sometimes because diffing floating points
        /// is weird
        let newRect = CGRect(x: bounds.origin.x,
                             y: bounds.origin.y,
                             width: bounds.width,
                             height: bounds.height + 2)
        
        let radii = CGSize(width: cornerRadius, height: cornerRadius)
        let boundsPath = UIBezierPath(rect: newRect)
        boundsPath.append(UIBezierPath(roundedRect: newRect,
                                       byRoundingCorners: [.topLeft, .topRight],
                                       cornerRadii: radii))
        
        maskLayer.path = boundsPath.cgPath
    }
}
