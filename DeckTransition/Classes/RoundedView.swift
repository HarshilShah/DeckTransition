//
//  RoundedView.swift
//  DeckTransition
//
//  Created by Rinat Gabdullin.
//  Copyright © 2017 Rinat Gabdullin. All rights reserved.
//

import UIKit

class RoundedView: UIView {

    private let maskLayer = CAShapeLayer()
    private let cornerRadius = CGFloat(8)

    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        configure()
    }

    private func configure() {
        layer.mask = maskLayer
        maskLayer.fillColor = UIColor.black.cgColor
        maskLayer.fillRule = kCAFillRuleEvenOdd
        autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let width = superview?.bounds.width ?? cornerRadius * CGFloat(2)
        frame = CGRect(origin: .zero, size: CGSize(width: width, height: cornerRadius))
        maskLayer.frame = bounds
        calculateMaskRect()
    }

    override func didMoveToSuperview() {
        setNeedsLayout()
    }

    override func didMoveToWindow() {
        backgroundColor = window?.backgroundColor
    }

    private func calculateMaskRect() {
        let body = UIBezierPath(rect: bounds)
        let height = bounds.height * CGFloat(2)

        let rect = CGRect(origin: .zero,
                          size: CGSize(width: bounds.width, height: height))

        let corners = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [.topLeft, .topRight],
            cornerRadii: CGSize(width: bounds.height, height: bounds.height))

        body.append(corners)
        maskLayer.path = body.cgPath
    }
}
