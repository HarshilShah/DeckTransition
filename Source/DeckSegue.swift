//
//  DeckSegue.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

/// A segue to implement the Deck transition via Storyboards
///
/// To use this, set your segue's class to `DeckSegue`, and its `kind` to
/// `custom`
public final class DeckSegue: UIStoryboardSegue {

    /// You can customize the segue transition by providing your own
    /// DeckTransitioningDelegate in 'prepare(for segue: sender:)'
    /// i.e.
    /// (segue as? DeckSegue)?.transitioningDelegate
    ///     = DeckTransitioningDelegate(isSwipeToDismissEnabled: false)
    public var transitioningDelegate: DeckTransitioningDelegate?

    /// Performs the visual transition for the Deck segue.
    public override func perform() {
        transitioningDelegate = transitioningDelegate ?? DeckTransitioningDelegate()
        destination.transitioningDelegate = transitioningDelegate
        destination.modalPresentationStyle = .custom
        source.present(destination, animated: true, completion: nil)
    }

}
