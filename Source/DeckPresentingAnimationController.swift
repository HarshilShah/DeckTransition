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
        
        containerView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        
        let roundedView = RoundedView()
        containerView.addSubview(roundedView)
        roundedView.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: Constants.cornerRadius)
        
        let finalFrameForPresentedView = transitionContext.finalFrame(for: presentedViewController)
        
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
				
                presentedViewController.view.frame = finalFrameForPresentedView
                
                roundedView.frame = CGRect(x: finalFrameForPresentedView.origin.x,
                                           y: finalFrameForPresentedView.origin.y,
                                           width: finalFrameForPresentedView.size.width,
                                           height: Constants.cornerRadius)
                
				self?.animation?()
            }, completion: { [weak self] finished in
                roundedView.removeFromSuperview()
                transitionContext.completeTransition(finished)
				self?.completion?(finished)
            }
        )
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration ?? Constants.defaultAnimationDuration
    }
    
}
