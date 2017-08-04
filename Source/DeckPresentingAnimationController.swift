//
//  DeckPresentingAnimationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

final class DeckPresentingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	
	// MARK:- Private variables
	
	private let duration: TimeInterval?
	private let animation: (() -> ())?
	private let completion: ((Bool) -> ())?
	
	// MARK:- Initializers
	
	init(duration: TimeInterval?, animation: (() -> ())?, completion: ((Bool) -> ())?) {
		self.duration = duration
		self.animation = animation
		self.completion = completion
	}
	
	// MARK:- UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        let presentingViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.from)!
        let presentedViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        
        let containerView = transitionContext.containerView
        
        let offScreenFrame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        
        containerView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = offScreenFrame
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                let scale: CGFloat = 1 - (Constants.topInsetForPresentingView * 2 / presentingViewController.view.frame.height)
                presentingViewController.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                presentingViewController.view.alpha = Constants.alphaForPresentingView
				presentingViewController.view.layer.cornerRadius = Constants.cornerRadius
				presentingViewController.view.layer.masksToBounds = true
				
                presentedViewController.view.frame = transitionContext.finalFrame(for: presentedViewController)
                presentedViewController.view.round(corners: [.topLeft, .topRight], withRadius: Constants.cornerRadius)
				self?.animation?()
            }, completion: { [weak self] finished in
                transitionContext.completeTransition(finished)
				self?.completion?(finished)
            }
        )
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration ?? Constants.defaultAnimationDuration
    }
    
}
