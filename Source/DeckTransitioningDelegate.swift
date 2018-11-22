//
//  DeckTransitioningDelegate.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit


/// This OptionSet makes it possible to determine points where haptic feedback should be performed. If passed into the corresponding method ```DeckTransitioningDelegate.useHapticFeedback(at:)```, the system will provide haptic feedback as configured.
public struct HapticFeedbackOptions: OptionSet {
    //Using an option set allows to configure multiple values and many combinations. An enum can not provide that level of flexibility. However, a OptionSet can not be bridged into Objective-C and therefore, a fallback needs to be implemented.
    
    
    public let rawValue: Int
    
    /// Haptic feedback will be performed when the presented ViewController is about to start animating onto screen.
    public static let whenPresenting = HapticFeedbackOptions(rawValue: 1 << 0)
    
    /// Haptic feedback will be performed when the presented ViewController is about to start animating off screen.
    public static let whenDismissing = HapticFeedbackOptions(rawValue: 1 << 1)
    
    /// Haptic feedback will be performed when the presented ViewController is done with its animated appearance and snapped into place.
    public static let whenPresentingIsFinished = HapticFeedbackOptions(rawValue: 1 << 2)
    
    /// Haptic feedback will be performed when the presented ViewController is done with its animated dismissal and therefore removed from the view hierarchy.
    public static let whenDismissingIsFinished = HapticFeedbackOptions(rawValue: 1 << 3)

    /// All cases of the OptionSet.
    static var allCases: HapticFeedbackOptions {
        return [HapticFeedbackOptions.whenPresenting, HapticFeedbackOptions.whenDismissing, HapticFeedbackOptions.whenPresentingIsFinished, HapticFeedbackOptions.whenDismissingIsFinished]
    }
    
    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

}


/// The DeckTransitioningDelegate class vends out the presentation and animation
/// controllers required to present a view controller with the Deck transition
/// style
///
/// The following snippet described the steps for presenting a given
/// `ModalViewController` with the `DeckTransitioningDelegate`
///
/// ```swift
/// let modal = ModalViewController()
/// let transitionDelegate = DeckTransitioningDelegate()
/// modal.transitioningDelegate = transitionDelegate
/// modal.modalPresentationStyle = .custom
/// present(modal, animated: true, completion: nil)
/// ```
public final class DeckTransitioningDelegate: NSObject, UIViewControllerTransitioningDelegate {
    
    // MARK: - Private variables
    
    private let isSwipeToDismissEnabled: Bool
    private let presentDuration: TimeInterval?
    private let presentAnimation: (() -> ())?
    private let presentCompletion: ((Bool) -> ())?
    private let dismissDuration: TimeInterval?
    private let dismissAnimation: (() -> ())?
    private let dismissCompletion: ((Bool) -> ())?
    private var hapticFeedbackOptions: HapticFeedbackOptions
    
    // MARK: - Initializers and Configuration
    
    /// Returns a transitioning delegate to perform a Deck transition. All
    /// parameters are optional. Swipe-to-dimiss is enabled by default. Leaving
    /// the duration parameters empty gives you animations with the default
    /// durations (0.3s for both)
    ///
    /// - Parameters:
    ///   - isSwipeToDismissEnabled: Whether the modal view controller should
    ///     be dismissed with a swipe gesture from top to bottom
    ///	  - presentDuration: The duration for the presentation animation
    ///   - presentAnimation: An animation block that will be performed
    ///		alongside the card presentation animation
    ///   - presentCompletion: A block that will be run after the card has been presented
    ///	  - dismissDuration: The duration for the dismissal animation
    ///   - dismissAnimation: An animation block that will be performed
    ///		alongside the card dismissal animation
    ///   - dismissCompletion: A block that will be run after the card has been dismissed
    ///   - shouldUseHapticFeedback: A flag that determines if haptic feedback should be given when the presentation or dismissal is performed. Currently, there is no way to specify options for the feedback in Objective-C, as the used Swift "OptionSet" type can not be exposed. The initializer is marked "@objc" and therefore exposing the options is not possible. As this initializer is marked "@objc", OptionSets can not be used as they can not be bridged into Objective-C. Due to this fact, the mentioned flag is introduced to provide a basic support for haptic feedback under Objective-C. If you are using Swift, please use ```DeckTransitioningDelegate.useHapticFeedback(at:)``` to configure the haptic feedback.
    @objc public init(isSwipeToDismissEnabled: Bool = true,
                      presentDuration: NSNumber? = nil,
                      presentAnimation: (() -> ())? = nil,
                      presentCompletion: ((Bool) -> ())? = nil,
                      dismissDuration: NSNumber? = nil,
                      dismissAnimation: (() -> ())? = nil,
                      dismissCompletion: ((Bool) -> ())? = nil,
                      shouldUseHapticFeedback: Bool = false) {
        self.isSwipeToDismissEnabled = isSwipeToDismissEnabled
        self.presentDuration = presentDuration?.doubleValue
        self.presentAnimation = presentAnimation
        self.presentCompletion = presentCompletion
        self.dismissDuration = dismissDuration?.doubleValue
        self.dismissAnimation = dismissAnimation
        self.dismissCompletion = dismissCompletion
        
        // Convert the provided flag to the internal OptionSet "HapticFeedbackOptions". As this initializer is marked "@objc", OptionSets can not be used as they can not be bridged into Objective-C. Due to this fact, the mentioned flag is introduced to provide a basic support for haptic feedback under Objective-C. The flag is obsolete once Objective-C support is dropped, since the OptionSet type provides more functionality (like combining multiple cases like .whenPresenting AND .whenDismissing, which is not expressible using enums).
        if shouldUseHapticFeedback {
            self.hapticFeedbackOptions = [.whenPresenting, .whenDismissing]
        }
        else {
            self.hapticFeedbackOptions = []
        }
    }

    
    /// This method configures at which points a haptic feedback should be performed. It must be called prior to the transition in order to be taken into consideration.
    ///
    /// - Parameter options: The options that specify at which points haptic feedback should be performed.
    @available(iOS 10.0, *)
    public func useHapticFeedback(at options: HapticFeedbackOptions) {
        hapticFeedbackOptions = options
    }
    
    /// This method changes the style of the haptic feedback. The latest provided value is used throughout all ongoing transitions.
    ///
    /// - Parameter style: The style that the hatic feedback generator should use.
    @available(iOS 10.0, *)
    public func changeFeedbackStyle(to style: UIImpactFeedbackGenerator.FeedbackStyle) {
        DeckHapticFeedbackGenerator.shared.changeFeedbackStyle(to: style)
    }
    
    // MARK: - UIViewControllerTransitioningDelegate
    
    /// Returns an animation controller that animates the modal presentation
    ///
    /// This is internal infrastructure handled entirely by UIKit and shouldn't
    /// be called directly
    ///
    /// - Parameters:
    ///   - presented: The modal view controller to be presented onscreen
    ///   - presenting: The view controller that will be presenting the modal
    ///   - source: The view controller whose `present` method is called
    /// - Returns: An animation controller that animates the modal presentation
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DeckPresentingAnimationController(duration: presentDuration)
    }
    
    /// Returns an animation controller that animates the modal dismissal
    ///
    /// This is internal infrastructure handled entirely by UIKit and shouldn't
    /// be called directly
    ///
    /// - Parameter dismissed: The modal view controller which will be dismissed
    /// - Returns: An animation controller that animates the modal dismisall
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DeckDismissingAnimationController(duration: dismissDuration)
    }
    
    /// Returns a presentation controller that manages the modal presentation
    ///
    /// This is internal infrastructure handled entirely by UIKit and shouldn't
    /// be called directly
    ///
    /// - Parameters:
    ///   - presented: The modal view controller
    ///   - presenting: The view controller which presented the modal
    ///   - source: The view controller whose `present` method was called to
    ///     present the modal
    /// - Returns: A presentation controller that manages the modal presentation
    public func presentationController(forPresented presented: UIViewController, presenting: UIViewController?, source: UIViewController) -> UIPresentationController? {
        let presentationController = DeckPresentationController(
            presentedViewController: presented,
            presenting: presenting,
            isSwipeToDismissGestureEnabled: isSwipeToDismissEnabled,
            presentAnimation: presentAnimation,
            presentCompletion: presentCompletion,
            dismissAnimation: dismissAnimation,
            dismissCompletion: dismissCompletion,
            hapticFeedbackOptions: hapticFeedbackOptions)
        presentationController.transitioningDelegate = self
        return presentationController
    }
    
}
