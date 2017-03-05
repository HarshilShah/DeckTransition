//
//  DeckPresentationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

/**
 Delegate that communicates to the `DeckPresentationController`
 whether the dismiss by pan gesture is enabled
*/
protocol DeckPresentationControllerDelegate {
    func isDismissGestureEnabled() -> Bool
}

final class DeckPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
    var transitioningDelegate: DeckPresentationControllerDelegate?
    var pan: UIPanGestureRecognizer?
    
    /**
     As best as I can tell using my iPhone and a bunch of iOS UI templates I
     came across online, 28 points is the distance between the top edge of the
     screen and the top edge of the modal view
    */
    override var frameOfPresentedViewInContainerView: CGRect {
        if let view = containerView {
            let offset: CGFloat = 28
            return CGRect(x: 0, y: offset, width: view.bounds.width, height: view.bounds.height - offset)
        } else {
            return .zero
        }
    }

    /**
     Method to ensure the layout is as required at the end of the presentation.
     This is required in case the modal is presented without animation.
    
     It also sets up the gesture recognizer to handle dismissal of the modal view
     controller by panning downwards
    */
    override func presentationTransitionDidEnd(_ completed: Bool) {
        if completed {
            let scale: CGFloat = 1 - (40/presentingViewController.view.frame.height)
            presentingViewController.view.transform = CGAffineTransform(scaleX: scale, y: scale)
            presentingViewController.view.alpha = 0.8
            presentingViewController.view.layer.cornerRadius = 8
			presentingViewController.view.layer.masksToBounds = true
            
            presentedViewController.view.frame = frameOfPresentedViewInContainerView
            presentedViewController.view.round(corners: [.topLeft, .topRight], withRadius: 8)
            
            pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan!.delegate = self
            pan!.maximumNumberOfTouches = 1
            presentedViewController.view.addGestureRecognizer(pan!)
        }
    }
    
    /**
     Method to ensure the layout is as required at the end of the dismissal.
     This is required in case the modal is dismissed without animation.
    */
    override func dismissalTransitionDidEnd(_ completed: Bool) {
        if completed {
            presentingViewController.view.alpha = 1
            presentingViewController.view.transform = .identity
            presentingViewController.view.layer.cornerRadius = 0
            
            if let view = containerView {
                let offScreenFrame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: view.bounds.height)
                presentedViewController.view.frame = offScreenFrame
            }
        }
    }
    
    /**
     Function to handle the modal setup's response to a change in constraints
     Basically the same changes as with the presentation animation are performed here.
    */
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        self.presentingViewController.view.transform = .identity
        
        coordinator.animate(
            alongsideTransition: { context in
                let scale: CGFloat = 1 - (40/self.presentingViewController.view.frame.height)
                self.presentingViewController.view.transform = CGAffineTransform(scaleX: scale, y: scale)
                
                let offset: CGFloat = 28
                let frame = CGRect(x: 0, y: offset, width: size.width, height: size.height - offset)
                self.presentedViewController.view.frame = frame
                
                self.presentedViewController.view.mask = nil
                self.presentedViewController.view.round(corners: [.topLeft, .topRight], withRadius: 8)
            }, completion: nil
        )
    }
    
    func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.isEqual(pan) else {
            return
        }
        
        switch gestureRecognizer.state {
        
        case .began:
            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: containerView)
        
        case .changed:
            if let view = presentedView {
                /**
                 The dismiss gesture needs to be enabled for the pan gesture
                 to do anything.
                */
                if transitioningDelegate?.isDismissGestureEnabled() ?? false {
                    let translation = gestureRecognizer.translation(in: view)
                    updatePresentedViewForTranslation(inVerticalDirection: translation.y)
                } else {
                    gestureRecognizer.setTranslation(.zero, in: view)
                }
            }
        
        case .ended:
            UIView.animate(
                withDuration: 0.25,
                animations: {
                    self.presentedView?.transform = .identity
                }
            )
        
        default: break
        
        }
    }
    
    /**
     Function to update the modal view for a particular amount of
     translation by panning in the vertical direction.
     
     The translation of the modal view is proportional to the panning
     distance until the `elasticThreshold`, after which it increases
     at a slower rate, given by `elasticFactor`, to indicate that the
     `dismissThreshold` is nearing.
     
     Once the `dismissThreshold` is reached, the modal view controller
     is dismissed.
     
     - parameter translation: The translation of the user's pan
     gesture in the container view in the vertical direction
    */
    private func updatePresentedViewForTranslation(inVerticalDirection translation: CGFloat) {
        
        let elasticThreshold: CGFloat = 120
		let dismissThreshold: CGFloat = 240
		
		let elasticFactor: CGFloat = 1/5
		let translationFactor: CGFloat = 1/2
		
        /**
         Nothing happens if the pan gesture is performed from bottom
         to top i.e. if the translation is negative
        */
        if translation >= 0 {
            let translationForModal: CGFloat = {
                if translation >= elasticThreshold {
					let frictionLength = translation - elasticThreshold
					let frictionTranslation = 30 * atan(frictionLength/120) + frictionLength/10
                    return frictionTranslation + (elasticThreshold * translationFactor)
                } else {
                    return translation * translationFactor
                }
            }()
			
            presentedView?.transform = CGAffineTransform(translationX: 0, y: translationForModal)
            
            if translation >= dismissThreshold {
                presentedViewController.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - UIGestureRecognizerDelegate methods
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard gestureRecognizer.isEqual(pan) else {
            return false
        }
        
        return true
    }
    
}
