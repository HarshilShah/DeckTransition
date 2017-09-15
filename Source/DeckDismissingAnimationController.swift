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
        roundedViewForPresentingView.cornerRadius = Constants.cornerRadius
        roundedViewForPresentingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roundedViewForPresentingView)
        
        /// At the end of the transition the rounded view has to have the same
        /// frame as the presentingView, except with a height equal to the
        /// cornerRadius
        let finalFrameForPresentingView = transitionContext.finalFrame(for: presentingViewController)
        let finalFrameForRoundedViewForPresentingView = CGRect(
            x: finalFrameForPresentingView.origin.x,
            y: finalFrameForPresentingView.origin.y,
            width: finalFrameForPresentingView.width,
            height: Constants.cornerRadius)
        roundedViewForPresentingView.frame = finalFrameForRoundedViewForPresentingView
        
        let scale: CGFloat = 1 - (ManualLayout.presentingViewTopInset * 2 / finalFrameForPresentingView.height)
        
        /// The rounded view needs to be scaled by the same amount as the
        /// presentingView, and also translated down by the same amount.
        /// Scaling happens with respect to the frame's center, so a
        /// translate-scale-translate needs to be done to ensure that the
        /// scaling is performed with respect to the top edge so it still lines
        /// up with the top edge of the presentingView
        let transformForRoundedViewForPresentingView = CGAffineTransform.identity
            .translatedBy(x: 0, y: ManualLayout.presentingViewTopInset)
            .translatedBy(x: 0, y: -finalFrameForRoundedViewForPresentingView.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: 0, y: finalFrameForRoundedViewForPresentingView.height / 2)
        roundedViewForPresentingView.transform = transformForRoundedViewForPresentingView
        
        let offScreenFrame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
      
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                roundedViewForPresentingView.transform = .identity
                
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
