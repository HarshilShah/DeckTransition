//
//  DeckPresentationController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

/// Delegate that communicates to the `DeckPresentationController` whether the
/// dismiss by pan gesture is enabled
protocol DeckPresentationControllerDelegate {
    func isDismissGestureEnabled() -> Bool
}

final class DeckPresentationController: UIPresentationController, UIGestureRecognizerDelegate {
	
	// MARK:- Internal variables
	
    var transitioningDelegate: DeckPresentationControllerDelegate?
    var pan: UIPanGestureRecognizer?
	
	// MARK:- Private variables
	
    private var roundedViewForPresentingView: RoundedView?
	private var roundedViewForPresentedView: RoundedView?
	
	private var backgroundView: UIView?
	private var presentingViewSnapshotView: UIView?
	private var cachedContainerWidth: CGFloat = 0
	private var aspectRatioConstraint: NSLayoutConstraint?
	
	private var presentAnimation: (() -> ())? = nil
	private var presentCompletion: ((Bool) -> ())? = nil
	private var dismissAnimation: (() -> ())? = nil
	private var dismissCompletion: ((Bool) -> ())? = nil
	
	// MARK:- Initializers
	
	convenience init(presentedViewController: UIViewController, presenting presentingViewController: UIViewController?, presentAnimation: (() -> ())? = nil, presentCompletion: ((Bool) ->())? = nil, dismissAnimation: (() -> ())? = nil, dismissCompletion: ((Bool) -> ())? = nil) {
		self.init(presentedViewController: presentedViewController, presenting: presentingViewController)
		self.presentAnimation = presentAnimation
		self.presentCompletion = presentCompletion
		self.dismissAnimation = dismissAnimation
		self.dismissCompletion = dismissCompletion
		
		NotificationCenter.default.addObserver(self, selector: #selector(updateForStatusBar), name: .UIApplicationDidChangeStatusBarFrame, object: nil)
	}
	
    override var frameOfPresentedViewInContainerView: CGRect {
        if let view = containerView {
            return CGRect(x: 0, y: Constants.topOffsetForPresentedView, width: view.bounds.width, height: view.bounds.height - Constants.topOffsetForPresentedView)
        } else {
            return .zero
        }
    }
	
	// MARK:- Presentation

    /// Method to ensure the layout is as required at the end of the
	/// presentation. This is required in case the modal is presented without
	/// animation.
    ///
	/// The various layout related functions performed by this method are:
	/// - Ensure that the view is in the same state as it would be after
	///   animated presentation
	/// - Create and add the `presentingViewSnapshotView` to the view hierarchy
	/// - Add a black background view to present to complete cover the
	///   `presentingViewController`'s view
	/// - Reset the `presentingViewController`'s view's `transform` so that
	///   further layout updates (such as status bar update) do not break the
	///   transform
	///
    /// It also sets up the gesture recognizer to handle dismissal of the modal
	/// view controller by panning downwards
    override func presentationTransitionDidEnd(_ completed: Bool) {
		guard let containerView = containerView else {
			return
		}
		
        if completed {
			roundedViewForPresentedView = RoundedView()
			roundedViewForPresentedView!.translatesAutoresizingMaskIntoConstraints = false
			containerView.addSubview(roundedViewForPresentedView!)
			
			presentedViewController.view.addObserver(self, forKeyPath: "frame", options: [.initial], context: nil)
			presentedViewController.view.addObserver(self, forKeyPath: "transform", options: [.initial], context: nil)
			presentedViewController.view.layer.mask = nil
            presentedViewController.view.frame = frameOfPresentedViewInContainerView
			presentAnimation?()
			
			presentingViewSnapshotView = UIView()
			presentingViewSnapshotView!.translatesAutoresizingMaskIntoConstraints = false
			containerView.insertSubview(presentingViewSnapshotView!, belowSubview: presentedViewController.view)
			
			NSLayoutConstraint.activate([
				presentingViewSnapshotView!.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
				presentingViewSnapshotView!.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
				presentingViewSnapshotView!.heightAnchor.constraint(
                    equalTo: containerView.heightAnchor,
                    constant: Constants.topInsetForPresentingView * -2),
			])
			
			updateSnapshotView()
            
            roundedViewForPresentingView = RoundedView()
            roundedViewForPresentingView!.translatesAutoresizingMaskIntoConstraints = false
            containerView.insertSubview(roundedViewForPresentingView!, aboveSubview: presentingViewSnapshotView!)
            
            NSLayoutConstraint.activate([
                roundedViewForPresentingView!.topAnchor.constraint(equalTo: presentingViewSnapshotView!.topAnchor),
                roundedViewForPresentingView!.leftAnchor.constraint(equalTo: presentingViewSnapshotView!.leftAnchor),
                roundedViewForPresentingView!.rightAnchor.constraint(equalTo: presentingViewSnapshotView!.rightAnchor),
                roundedViewForPresentingView!.heightAnchor.constraint(equalToConstant: Constants.cornerRadius)
            ])
			
			backgroundView = UIView()
			backgroundView!.backgroundColor = .black
			backgroundView!.translatesAutoresizingMaskIntoConstraints = false
			containerView.insertSubview(backgroundView!, belowSubview: presentingViewSnapshotView!)
			
			NSLayoutConstraint.activate([
				backgroundView!.topAnchor.constraint(equalTo: containerView.window!.topAnchor),
				backgroundView!.leftAnchor.constraint(equalTo: containerView.window!.leftAnchor),
				backgroundView!.rightAnchor.constraint(equalTo: containerView.window!.rightAnchor),
				backgroundView!.bottomAnchor.constraint(equalTo: containerView.window!.bottomAnchor)
			])
			
			presentingViewController.view.transform = .identity
			
            pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
            pan!.delegate = self
            pan!.maximumNumberOfTouches = 1
            pan!.cancelsTouchesInView = false
            presentedViewController.view.addGestureRecognizer(pan!)
        }
		
		presentCompletion?(completed)
    }
	
	// MARK:- Layout update methods
	
	/// This method updates the aspect ratio of the snapshot view
	///
	/// The `snapshotView`'s aspect ratio needs to be updated here because even
	/// though it is updated with the `snapshotView` in `viewWillTransition:`,
	/// the transition is janky unless it's updated before, hence it's performed
	/// here as well, It's also an inexpensive method since constraints are
	/// modified only when a change is actually needed
	override func containerViewWillLayoutSubviews() {
		super.containerViewWillLayoutSubviews()
		
		updateSnapshotViewAspectRatio()
        
        if let roundedView = roundedViewForPresentedView {
            containerView?.bringSubview(toFront: roundedView)
        }
        
        UIView.animate(withDuration: 0.1) { [weak self] in
            guard let `self` = self else { return }
            self.presentedViewController.view.frame = self.frameOfPresentedViewInContainerView
        }
	}
    
    /// Method to handle the modal setup's response to a change in
	/// orientation, size, etc.
	///
	/// Everything else is handled by AutoLayout or `willLayoutSubviews`; the
	/// express purpose of this method is to update the snapshot view since that
	/// is a relatively expensive operation and only makes sense on orientation
	/// change
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
		
		coordinator.animate(
			alongsideTransition: nil,
			completion: { [weak self] _ in
				self?.updateSnapshotView()
			}
        )
    }
	
	/// Method to handle updating the view when the status bar's height changes
	///
	/// The `containerView`'s frame is always supposed to be the go 20 pixels
	/// or 1 normal status bar height under the status bar itself, even when the
	/// status bar is of double height, to retain consistency with the system's
	/// default behaviour
	///
	/// The containerView is the only thing that received layout updates;
	/// AutoLayout and the snapshotView method handle the rest. Additionally,
	/// the mask for the `presentedViewController` is also reset
	@objc func updateForStatusBar() {
		guard let containerView = containerView else {
			return
		}
		
		/// The `presentingViewController.view` often animated "before" the mask
		/// view that should fully cover it, so it's hidden before altering the
		/// view hierarchy, and then revealed after the animations are finished
		presentingViewController.view.alpha = 0
		
		let fullHeight = containerView.window!.frame.size.height
		let statusBarHeight: CGFloat = {
			let tempHeight = UIApplication.shared.statusBarFrame.height
			if tempHeight >= 20 {
				return tempHeight - 20
			} else {
				return tempHeight
			}
		}()
		
		let currentHeight = containerView.frame.height
		let newHeight = fullHeight - statusBarHeight
		
		UIView.animate(
			withDuration: 0.1,
			animations: {
				containerView.frame.origin.y -= newHeight - currentHeight
			}, completion: { [weak self] _ in
				self?.presentingViewController.view.alpha = Constants.alphaForPresentingView
				containerView.frame = CGRect(x: 0, y: statusBarHeight, width: containerView.frame.width, height: newHeight)
			}
		)
	}
	
	// MARK:- Snapshot view update methods
	
	/// Method to update the snapshot view showing a representation of the
	/// `presentingViewController`'s view
	///
	/// The method can only be fired when the snapshot view has been set up, and
	/// then only when the width of the container is updated
	///
	/// It resets the aspect ratio constraint for the snapshot view first, and
	/// then generates a new snapshot of the `presentingViewController`'s view,
	/// and then replaces the existing snapshot with it
	private func updateSnapshotView() {
		guard let presentingViewSnapshotView = presentingViewSnapshotView else {
			return
		}
		
		updateSnapshotViewAspectRatio()
		
		if let snapshotView = presentingViewController.view.snapshotView(afterScreenUpdates: true) {
			presentingViewSnapshotView.subviews.forEach { $0.removeFromSuperview() }
			
			snapshotView.translatesAutoresizingMaskIntoConstraints = false
			presentingViewSnapshotView.addSubview(snapshotView)
			
			NSLayoutConstraint.activate([
				snapshotView.topAnchor.constraint(equalTo: presentingViewSnapshotView.topAnchor),
				snapshotView.leftAnchor.constraint(equalTo: presentingViewSnapshotView.leftAnchor),
				snapshotView.rightAnchor.constraint(equalTo: presentingViewSnapshotView.rightAnchor),
				snapshotView.bottomAnchor.constraint(equalTo: presentingViewSnapshotView.bottomAnchor)
			])
		}
	}
	
	/// Thie method updates the aspect ratio of the snapshot view used to
	/// represent the presenting view controller.
	///
	/// The aspect ratio is only updated when the width of the container changes
	/// i.e. when just the status bar moves, nothing happens
	private func updateSnapshotViewAspectRatio() {
		guard
			let containerView = containerView,
			let presentingViewSnapshotView = presentingViewSnapshotView,
			cachedContainerWidth != containerView.bounds.width
		else {
			return
		}
		
		cachedContainerWidth = containerView.bounds.width
		aspectRatioConstraint?.isActive = false
		let aspectRatio = containerView.bounds.width / containerView.bounds.height
		aspectRatioConstraint = presentingViewSnapshotView.widthAnchor.constraint(equalTo: presentingViewSnapshotView.heightAnchor, multiplier: aspectRatio)
		aspectRatioConstraint?.isActive = true
	}
	
	// MARK:- Presented view KVO + Rounded view update methods
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "transform" || keyPath == "frame", let view = object as? UIView {
			let offset = view.frame.origin.y
			updateRoundedView(forOffset: offset)
		}
	}
	
	private func updateRoundedView(forOffset offset: CGFloat) {
		guard let roundedView = roundedViewForPresentedView else {
			return
		}
		
		roundedView.frame = CGRect(x: 0, y: offset, width: containerView!.bounds.width, height: Constants.cornerRadius)
	}
	
	// MARK:- Dismissal
	
	/// Method to prepare the view hirarchy for the dismissal animation
	///
	/// The stuff with snapshots and the black background should be invisible to
	/// the dismissal animation, so this method effectively removes them and
	/// restores the state of the `presentingViewController`'s view to the
	/// expected state at the end of the presenting animation
	override func dismissalTransitionWillBegin() {
		let scale: CGFloat = 1 - (Constants.topInsetForPresentingView * 2 / presentingViewController.view.frame.height)
		presentingViewController.view.transform = CGAffineTransform(scaleX: scale, y: scale)
		backgroundView?.removeFromSuperview()
        presentingViewSnapshotView?.removeFromSuperview()
        roundedViewForPresentingView?.removeFromSuperview()
        roundedViewForPresentedView?.removeFromSuperview()
	}
	
	/// Method to ensure the layout is as required at the end of the dismissal.
	/// This is required in case the modal is dismissed without animation.
	override func dismissalTransitionDidEnd(_ completed: Bool) {
		if completed {
            presentedViewController.view.removeObserver(self, forKeyPath: "frame")
            presentedViewController.view.removeObserver(self, forKeyPath: "transform")
            
			presentingViewController.view.frame = containerView!.frame
			presentingViewController.view.transform = .identity
			dismissAnimation?()
			
			if let view = containerView {
				let offScreenFrame = CGRect(x: 0, y: view.bounds.height, width: view.bounds.width, height: view.bounds.height)
				presentedViewController.view.frame = offScreenFrame
				presentedViewController.view.transform = .identity
			}
		}
		
		dismissCompletion?(completed)
	}
	
	// MARK:- Gesture handling
	
    @objc private func handlePan(gestureRecognizer: UIPanGestureRecognizer) {
        guard gestureRecognizer.isEqual(pan) else {
            return
        }
        
        switch gestureRecognizer.state {
        
        case .began:
            gestureRecognizer.setTranslation(CGPoint(x: 0, y: 0), in: containerView)
        
        case .changed:
            if let view = presentedView {
                /// The dismiss gesture needs to be enabled for the pan gesture
                /// to do anything.
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
    
    /// Method to update the modal view for a particular amount of translation
	/// by panning in the vertical direction.
	///
	/// The translation of the modal view is proportional to the panning
	/// distance until the `elasticThreshold`, after which it increases at a
	/// slower rate, given by `elasticFactor`, to indicate that the
	/// `dismissThreshold` is nearing.
    ///
    /// Once the `dismissThreshold` is reached, the modal view controller is
	/// dismissed.
    ///
    /// - parameter translation: The translation of the user's pan gesture in
    ///   the container view in the vertical direction
    private func updatePresentedViewForTranslation(inVerticalDirection translation: CGFloat) {
        
        let elasticThreshold: CGFloat = 120
		let dismissThreshold: CGFloat = 240
		
		let translationFactor: CGFloat = 1/2
		
        /// Nothing happens if the pan gesture is performed from bottom
        /// to top i.e. if the translation is negative
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
