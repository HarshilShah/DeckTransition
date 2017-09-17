//
//  CornerView.swift
//  DeckTransition
//
//  Created by Harshil Shah on 17/09/17.
//  Copyright © 2017 Harshil Shah. All rights reserved.
//

import UIKit

final class CornerView: UIView {
    
    // MARK:- Public variables
    
    var cornerRadius: CGFloat = 0 {
        didSet {
            updateCornerShape()
        }
    }
    
    var corner: Corner? {
        didSet { updateCornerShape() }
    }
    
    // MARK:- Private variables
    
    private let cornerShapeLayer = CAShapeLayer()
    
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
        layer.addSublayer(cornerShapeLayer)
        cornerShapeLayer.fillColor = UIColor.black.cgColor
    }
    
    // MARK:- UIView methods
    
    override func layoutSubviews() {
        super.layoutSubviews()
        cornerShapeLayer.frame = bounds
        updateCornerShape()
    }
    
    // MARK:- Private methods
    
    private func updateCornerShape() {
        guard let corner = corner else {
            cornerShapeLayer.path = nil
            return
        }
        
        let side = cornerRadius
        let size = CGSize(width: side, height: side)
        let targetRect = CGRect(withCorner: corner, at: bounds.getCorner(corner), size: size)
        
        /// Each corner's curved path is created by:
        ///
        /// 1. Moving to the actual corner point
        /// 2. Drawing a line along the x-axis towards the center by the same
        ///    amount as the required corner radius
        /// 3. Drawing a quadrant of the required radius with its center as one
        ///    unit along both x and y axes from the corner towards the center
        /// 4. Drawing a line back to the corner point
        let path: UIBezierPath = {
            switch corner {
                
            case .topLeft:
                let tempPath = UIBezierPath()
                tempPath.move(to: targetRect.topLeft)
                tempPath.addLine(to: targetRect.topRight)
                tempPath.addArc(withCenter: targetRect.bottomRight, radius: side, startAngle: .pi * 3/2, endAngle: .pi, clockwise: false)
                tempPath.addLine(to: targetRect.topLeft)
                return tempPath
                
            case .topRight:
                let tempPath = UIBezierPath()
                tempPath.move(to: targetRect.topRight)
                tempPath.addLine(to: targetRect.topLeft)
                tempPath.addArc(withCenter: targetRect.bottomLeft, radius: side, startAngle: .pi * 3/2, endAngle: 0, clockwise: true)
                tempPath.addLine(to: targetRect.topRight)
                return tempPath
                
            case .bottomLeft:
                let tempPath = UIBezierPath()
                tempPath.move(to: targetRect.bottomLeft)
                tempPath.addLine(to: targetRect.bottomRight)
                tempPath.addArc(withCenter: targetRect.topRight, radius: side, startAngle: .pi/2, endAngle: .pi, clockwise: true)
                tempPath.addLine(to: targetRect.bottomLeft)
                return tempPath
                
            case .bottomRight:
                let tempPath = UIBezierPath()
                tempPath.move(to: targetRect.bottomRight)
                tempPath.addLine(to: targetRect.bottomLeft)
                tempPath.addArc(withCenter: targetRect.topLeft, radius: side, startAngle: .pi/2, endAngle: 0, clockwise: false)
                tempPath.addLine(to: targetRect.bottomRight)
                return tempPath
                
            }
        }()
        
        cornerShapeLayer.path = path.cgPath
    }
    
}


