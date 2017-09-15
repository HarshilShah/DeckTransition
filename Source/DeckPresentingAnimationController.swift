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
        
        let scale: CGFloat = 1 - (ManualLayout.presentingViewTopInset * 2 / presentingViewController.view.frame.height)
        
        let roundedViewForPresentingView = RoundedView()
        roundedViewForPresentingView.cornerRadius = Constants.cornerRadius
        roundedViewForPresentingView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roundedViewForPresentingView)
        
        /// Initially the rounded view has the same frame as the presentingView,
        /// except with a height equal to the cornerRadius
        let initialFrameForRoundedViewForPresentingView = CGRect(
            x: presentingViewController.view.frame.origin.x,
            y: presentingViewController.view.frame.origin.y,
            width: presentingViewController.view.frame.width,
            height: Constants.cornerRadius)
        roundedViewForPresentingView.frame = initialFrameForRoundedViewForPresentingView
        
        /// The rounded view needs to be scaled by the same amount as the
        /// presentingView, and also translated down by the same amount.
        /// Scaling happens with respect to the frame's center, so a
        /// translate-scale-translate needs to be done to ensure that the
        /// scaling is performed with respect to the top edge so it still lines
        /// up with the top edge of the presentingView
        let transformForRoundedViewForPresentingView = CGAffineTransform.identity
            .translatedBy(x: 0, y: ManualLayout.presentingViewTopInset)
            .translatedBy(x: 0, y: -initialFrameForRoundedViewForPresentingView.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: 0, y: initialFrameForRoundedViewForPresentingView.height / 2)
        
        containerView.addSubview(presentedViewController.view)
        presentedViewController.view.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        
        let roundedViewForPresentedView = RoundedView()
        containerView.addSubview(roundedViewForPresentedView)
        roundedViewForPresentedView.frame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: Constants.cornerRadius)
        
        let finalFrameForPresentedView = transitionContext.finalFrame(for: presentedViewController)
        let finalFrameForRoundedViewForPresentedView = CGRect(
            x: finalFrameForPresentedView.origin.x,
            y: finalFrameForPresentedView.origin.y,
            width: finalFrameForPresentedView.width,
            height: Constants.cornerRadius)
        
        UIView.animate(
            withDuration: transitionDuration(using: transitionContext),
            delay: 0,
            options: .curveEaseOut,
            animations: { [weak self] in
                presentingViewController.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                presentingViewController.view.alpha = Constants.alphaForPresentingView
                
                roundedViewForPresentingView.cornerRadius = Constants.cornerRadius
                roundedViewForPresentingView.transform = transformForRoundedViewForPresentingView
				
                presentedViewController.view.frame = finalFrameForPresentedView
                roundedViewForPresentedView.frame = finalFrameForRoundedViewForPresentedView
                
				self?.animation?()
            }, completion: { [weak self] finished in
                roundedViewForPresentingView.removeFromSuperview()
                roundedViewForPresentedView.removeFromSuperview()
                transitionContext.completeTransition(finished)
                self?.completion?(finished)
            }
        )
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration ?? Constants.defaultAnimationDuration
    }
    
}
