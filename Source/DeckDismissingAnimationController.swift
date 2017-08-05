//
//  DeckDismissingAnimationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

final class DeckDismissingAnimationController: NSObject, UIViewControllerAnimatedTransitioning {
	
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
        let presentingViewController = transitionContext.viewController(forKey: .to)!
        let presentedViewController = transitionContext.viewController(forKey: .from)!
        
        let containerView = transitionContext.containerView
        
        let roundedViewForPresentingView = RoundedView()
        roundedViewForPresentingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roundedViewForPresentingView)
        
        let initialFrameForRoundedPresentingView = CGRect(
            x: presentingViewController.view.frame.origin.x,
            y: presentingViewController.view.frame.origin.y,
            width: presentingViewController.view.frame.width,
            height: Constants.cornerRadius)
        roundedViewForPresentingView.frame = initialFrameForRoundedPresentingView
        
        let finalFrameForPresentingView = transitionContext.finalFrame(for: presentingViewController)
        let finalFrameForRoundedViewForPresentingView = CGRect(
            x: finalFrameForPresentingView.origin.x,
            y: finalFrameForPresentingView.origin.y,
            width: finalFrameForPresentingView.width,
            height: Constants.cornerRadius)
        
        let offScreenFrame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
      
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                roundedViewForPresentingView.cornerRadius = 0
                roundedViewForPresentingView.frame = finalFrameForRoundedViewForPresentingView
                presentingViewController.view.alpha = 1
                presentingViewController.view.transform = .identity
                
                presentedViewController.view.frame = offScreenFrame
				self?.animation?()
            }, completion: { [weak self] finished in
                roundedViewForPresentingView.removeFromSuperview()
                transitionContext.completeTransition(finished)
				self?.completion?(finished)
            })
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration ?? Constants.defaultAnimationDuration
    }
	
}
