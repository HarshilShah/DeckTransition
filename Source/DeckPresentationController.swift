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

/// A protocol to communicate to the transition that an update of the snapshot
/// view is required. This is adopted only by the presentation controller
public protocol DeckSnapshotUpdater {
    
    /// For various reasons (performance, the way iOS handles safe area,
    /// layout issues, etc.) this transition uses a snapshot view of your
    /// `presentingViewController` and not the live view itself.
    ///
    /// In some cases this snapshot might become outdated before the dismissal,
    /// and for those cases you can request to have the snapshot updated. While
    /// the transition only shows a small portion of the presenting view, in
    /// some cases that might become inconsistent enough to demand an update.
    ///
    /// This is an expensive process and should only be used if necessary, for
    /// example if you are updating your entire app's theme.
    func requestPresentedViewSnapshotUpdate()
}

final class DeckPresentationController: UIPresentationController, UIGestureRecognizerDelegate, DeckSnapshotUpdater {
	
	// MARK:- Internal variables
	
    var transitioningDelegate: DeckPresentationControllerDelegate?
	
	// MARK:- Private variables
    
    private var pan: UIPanGestureRecognizer?
    
    private let backgroundView = UIView()
	private let presentingViewSnapshotView = UIView()
    private let roundedViewForPresentingView = RoundedView()
    private let roundedViewForPresentedView = RoundedView()
    
	private var cachedContainerWidth: CGFloat = 0
    private var snapshotViewHeightConstraint: NSLayoutConstraint?
	private var snapshotViewAspectRatioConstraint: NSLayoutConstraint?
	
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
    
    // MARK:- Public methods
    
    public func requestPresentedViewSnapshotUpdate() {
        updateSnapshotView()
    }
    
    // MARK:- Sizing
    
    private var statusBarHeight: CGFloat {
        return UIApplication.shared.statusBarFrame.height
    }
	
    override var frameOfPresentedViewInContainerView: CGRect {
        guard let containerView = containerView else {
            return .zero
        }
        
        let yOffset = ManualLayout.presentingViewTopInset + Constants.insetForPresentedView
        
        return CGRect(x: 0,
                      y: yOffset,
                      width: containerView.bounds.width,
                      height: containerView.bounds.height - yOffset)
    }
	
	// MARK:- Presentation
    
    override func presentationTransitionWillBegin() {
        guard let containerView = containerView, let window = containerView.window else {
            return
        }
        
        if let animated = presentedViewController.transitionCoordinator?.isAnimated {
            presentedViewController.beginAppearanceTransition(true, animated: animated)
            presentingViewController.beginAppearanceTransition(false, animated: animated)
        }
        
        let scale: CGFloat = 1 - (ManualLayout.presentingViewTopInset * 2 / containerView.frame.height)
        
        roundedViewForPresentedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(roundedViewForPresentedView)
        presentedViewController.view.addObserver(self, forKeyPath: "frame", options: [.initial], context: nil)
        presentedViewController.view.addObserver(self, forKeyPath: "transform", options: [.initial], context: nil)
        
        containerView.insertSubview(presentingViewSnapshotView, belowSubview: presentedViewController.view)
        presentingViewSnapshotView.frame = containerView.bounds
        updateSnapshotView()
        
        containerView.insertSubview(roundedViewForPresentingView, aboveSubview: presentingViewSnapshotView)
        
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
        
        backgroundView.backgroundColor = .black
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        containerView.insertSubview(backgroundView, belowSubview: presentingViewSnapshotView)
        
        NSLayoutConstraint.activate([
            backgroundView.topAnchor.constraint(equalTo: window.topAnchor),
            backgroundView.leftAnchor.constraint(equalTo: window.leftAnchor),
            backgroundView.rightAnchor.constraint(equalTo: window.rightAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: window.bottomAnchor)
        ])
        
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [unowned self] context in
                self.presentAnimation?()
                self.presentingViewSnapshotView.alpha = Constants.alphaForPresentingView
                self.presentingViewSnapshotView.transform = CGAffineTransform(scaleX: scale, y: scale)
                self.roundedViewForPresentingView.transform = transformForRoundedViewForPresentingView
            }
        )
    }

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
        
        presentedViewController.endAppearanceTransition()
        presentingViewController.endAppearanceTransition()
        
        presentedViewController.view.frame = frameOfPresentedViewInContainerView
        
        presentingViewSnapshotView.transform = .identity
        presentingViewSnapshotView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            presentingViewSnapshotView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            presentingViewSnapshotView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        updateSnapshotViewAspectRatio()
        
        roundedViewForPresentingView.transform = .identity
        roundedViewForPresentingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            roundedViewForPresentingView.topAnchor.constraint(equalTo: presentingViewSnapshotView.topAnchor),
            roundedViewForPresentingView.leftAnchor.constraint(equalTo: presentingViewSnapshotView.leftAnchor),
            roundedViewForPresentingView.rightAnchor.constraint(equalTo: presentingViewSnapshotView.rightAnchor),
            roundedViewForPresentingView.heightAnchor.constraint(equalToConstant: Constants.cornerRadius)
        ])
        
        pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan))
        pan!.delegate = self
        pan!.maximumNumberOfTouches = 1
        pan!.cancelsTouchesInView = false
        presentedViewController.view.addGestureRecognizer(pan!)
		
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
        containerView?.bringSubview(toFront: roundedViewForPresentedView)
        
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
                self?.updateSnapshotViewAspectRatio()
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
	@objc private func updateForStatusBar() {
		guard let containerView = containerView else {
			return
		}
		
		/// The `presentingViewController.view` often animated "before" the mask
		/// view that should fully cover it, so it's hidden before altering the
		/// view hierarchy, and then revealed after the animations are finished
        presentingViewController.view.alpha = 0
		
		let fullHeight = containerView.window!.frame.size.height
		
		let currentHeight = containerView.frame.height
		let newHeight = fullHeight - ManualLayout.containerViewTopInset
		
		UIView.animate(
			withDuration: 0.1,
			animations: {
				containerView.frame.origin.y -= newHeight - currentHeight
			}, completion: { [weak self] _ in
                self?.presentingViewController.view.alpha = 1
                containerView.frame = CGRect(x: 0, y: ManualLayout.containerViewTopInset, width: containerView.frame.width, height: newHeight)
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
	
	/// Thie method updates the aspect ratio and the height of the snapshot view
    /// used to represent the presenting view controller.
	///
	/// The aspect ratio is only updated when the width of the container changes
	/// i.e. when just the status bar moves, nothing happens
    private func updateSnapshotViewAspectRatio() {
		guard let containerView = containerView,
              presentingViewSnapshotView.translatesAutoresizingMaskIntoConstraints == false,
			  cachedContainerWidth != containerView.bounds.width
		else {
			return
		}
		
		cachedContainerWidth = containerView.bounds.width
        
        snapshotViewHeightConstraint?.isActive = false
		snapshotViewAspectRatioConstraint?.isActive = false
        
        let heightConstant = ManualLayout.presentingViewTopInset * -2
		let aspectRatio = containerView.bounds.width / containerView.bounds.height
        
        roundedViewForPresentingView.cornerRadius = Constants.cornerRadius * (1 - (heightConstant / containerView.frame.height))
        snapshotViewHeightConstraint = presentingViewSnapshotView.heightAnchor.constraint(equalTo: containerView.heightAnchor,constant: heightConstant)
        snapshotViewAspectRatioConstraint = presentingViewSnapshotView.widthAnchor.constraint(equalTo: presentingViewSnapshotView.heightAnchor, multiplier: aspectRatio)
		
        snapshotViewHeightConstraint?.isActive = true
        snapshotViewAspectRatioConstraint?.isActive = true
	}
	
	// MARK:- Presented view KVO + Rounded view update methods
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		if keyPath == "transform" || keyPath == "frame", let view = object as? UIView {
			let offset = view.frame.origin.y
			updateRoundedView(forOffset: offset)
		}
	}
	
	private func updateRoundedView(forOffset offset: CGFloat) {
		roundedViewForPresentedView.frame = CGRect(x: 0, y: offset, width: containerView!.bounds.width, height: Constants.cornerRadius)
	}
	
	// MARK:- Dismissal
	
	/// Method to prepare the view hirarchy for the dismissal animation
	///
	/// The stuff with snapshots and the black background should be invisible to
	/// the dismissal animation, so this method effectively removes them and
	/// restores the state of the `presentingViewController`'s view to the
	/// expected state at the end of the presenting animation
	override func dismissalTransitionWillBegin() {
        guard let containerView = containerView else {
            return
        }
        
        if let animated = presentedViewController.transitionCoordinator?.isAnimated {
            presentingViewController.beginAppearanceTransition(true, animated: animated)
            presentedViewController.beginAppearanceTransition(false, animated: animated)
        }
        
        let scale: CGFloat = 1 - (ManualLayout.presentingViewTopInset * 2 / containerView.frame.height)
        
        snapshotViewHeightConstraint?.isActive = false
        snapshotViewHeightConstraint = self.presentingViewSnapshotView.heightAnchor.constraint(equalTo: containerView.heightAnchor)
        snapshotViewHeightConstraint?.isActive = true
        
        let finalFrameForRoundedViewForPresentingView = CGRect(
            x: presentingViewController.view.frame.origin.x,
            y: presentingViewController.view.frame.origin.y,
            width: presentingViewController.view.frame.width,
            height: Constants.cornerRadius)
        roundedViewForPresentingView.frame = finalFrameForRoundedViewForPresentingView
        
        let transformForRoundedViewForPresentingView = CGAffineTransform.identity
            .translatedBy(x: 0, y: ManualLayout.presentingViewTopInset)
            .translatedBy(x: 0, y: -finalFrameForRoundedViewForPresentingView.height / 2)
            .scaledBy(x: scale, y: scale)
            .translatedBy(x: 0, y: finalFrameForRoundedViewForPresentingView.height / 2)
        roundedViewForPresentingView.transform = transformForRoundedViewForPresentingView
        
        presentedViewController.transitionCoordinator?.animate(
            alongsideTransition: { [unowned self] context in
                self.dismissAnimation?()
                self.presentingViewSnapshotView.alpha = 1
                self.presentingViewSnapshotView.layoutIfNeeded()
                self.roundedViewForPresentingView.transform = .identity
            }
        )
	}
	
	/// Method to ensure the layout is as required at the end of the dismissal.
	/// This is required in case the modal is dismissed without animation.
	override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard let containerView = containerView else {
            return
        }
        
        presentedViewController.endAppearanceTransition()
        presentingViewController.endAppearanceTransition()
        
		backgroundView.removeFromSuperview()
        presentingViewSnapshotView.removeFromSuperview()
        roundedViewForPresentingView.removeFromSuperview()
        
        presentingViewController.view.frame = containerView.frame
        presentingViewController.view.transform = .identity
        
        let offscreenFrame = CGRect(x: 0, y: containerView.bounds.height, width: containerView.bounds.width, height: containerView.bounds.height)
        presentedViewController.view.frame = offscreenFrame
        presentedViewController.view.transform = .identity
        
        presentedViewController.view.removeObserver(self, forKeyPath: "frame")
        presentedViewController.view.removeObserver(self, forKeyPath: "transform")
		
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
