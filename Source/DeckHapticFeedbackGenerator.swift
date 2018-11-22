//
//  DeckHapticFeedbackGenerator.swift
//  DeckTransition
//
//  Created by Andreas Neusüß on 22.11.18.
//  Copyright © 2018 Harshil Shah. All rights reserved.
//

import UIKit

/** This class is used to control the haptic feedback. It provides methods for configuring the style of the feedback. Currently, only impact-styled feedbacks are supported (with weight ```light```, ```medium``` or ```heavy```).
 
 This class provides a singleton. The reson for this is that ```UIImpactFeedbackGenerator``` is only available on iOS 10 and newer. Additionally, a reference to it must be stored strongly. Otherwise the feedback will not be performed. Swift does not allow stored properties to be marked ```@available``` and therefore either the entire class that uses the feedback-generator must be marked ```@available``` or the ```UIImpactFeedbackGenerator``` needs to be encapsulated. This class uses the secound approach.
 In doing so, only small function calls needs to be wrapped in ```if #available``` checks.
 The downside of this approach is that only one kind of feedback can be performed.
 
 Please ensure to call ```DeckHapticFeedbackGenerator.shared.prepare()``` to power up the device's TapticEngine.
 */
@available(iOS 10.0, *)
final class DeckHapticFeedbackGenerator: NSObject {
    
    /// The singleton that should be used to trigger haptic feedback. Please ensure to call ```DeckHapticFeedbackGenerator.shared.prepare()``` to power up the device's TapticEngine.
    static let shared = DeckHapticFeedbackGenerator()
    
    /// The feedback style that should be performed.
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .light {
        didSet {
            feedbackGenerator = createFeedbackGenerator(using: style)
        }
    }
    
    // Make the initializer unavailable for the public so that the shared instance is used.
    private override init() {
        super.init()
        feedbackGenerator = createFeedbackGenerator(using: style)
    }
    
    /// The internally used feedback generator. Must be held strongly in order to perform feedback. Make sure to call ```prepare``` prior to any feedback action.
    private var feedbackGenerator: UIImpactFeedbackGenerator?
    
    
    /// This method constructs a UIImpactFeedbackGenerator from a given feedback style.
    ///
    /// - Parameter style: The style that should be used for the feedback.
    /// - Returns: The new UIImpactFeedbackGenerator.
    private func createFeedbackGenerator(using style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        return UIImpactFeedbackGenerator(style: style)
    }

    
    /// This method prepares the device's TapticEngine. Call this method about one second before the haptic feedback should be performed`(if possible). The TapticEngine will stay powered on about one or two seconds.
    func prepare() {
        feedbackGenerator?.prepare()
    }
    
    /// This method performs the haptic feedback. Please call ```prepare``` about one second in advance. Only then it is save to coordinate UI interactions with the haptic feedback. It will use the style provided by a call to ```DeckHapticFeedbackGenerator`.shared.changeFeedbackStyle(to:)```.
    func perform() {
        // If not done already, a call to "prepare" poweres up the TapticEngine.
        prepare()
        
        feedbackGenerator?.impactOccurred()
    }
    
    
    /// This method changed the style of the haptic feedback.
    ///
    /// - Parameter style: The new style that should be used for the feedback.
    func changeFeedbackStyle(to style: UIImpactFeedbackGenerator.FeedbackStyle) {
        self.style = style
    }
}

// Use an extension to encapsulate feedback providing. In doing so, every @availability checking can be performed in this extension.

extension DeckPresentationController {
    
    /// Performs the haptic feedback.
    func prepareHapticFeedback() {
        if #available(iOS 10.0, *) {
            DeckHapticFeedbackGenerator.shared.prepare()
        }
    }
    /// Prepares the TapticEngine to perform haptic feedback in the near future (lasts up to two seconds).
    func performHapticFeedback() {
        if #available(iOS 10.0, *) {
            DeckHapticFeedbackGenerator.shared.perform()
        }
    }
}
