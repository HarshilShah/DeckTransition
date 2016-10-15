//
//  DeckTransitioningDelegate.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

public final class DeckTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate, DeckPresentationControllerDelegate {
    
    /**
     A variable indicating whether or not the presenting view controller
     can currently be dismissed using a pan gestures from top to bottom.
     
     When set to `true`, this allows the presented modal view to be
     dismissed using a pan gesture. The default value of this property
     is true.
    */
    public var isDismissEnabled = true
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DeckPresentingAnimationController()
    }
    
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DeckDismissingAnimationController()
    }
    
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = DeckPresentationController(presentedViewController: presented, presenting: presenting)
        presentationController.transitioningDelegate = self
        return presentationController
    }
    
    // MARK: - DeckPresentationControllerDelegate methods
    
    internal func isDismissGestureEnabled() -> Bool {
        return isDismissEnabled
    }
    
}
