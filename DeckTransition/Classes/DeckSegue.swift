//
//  DeckSegue.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit

/// A segue to implement the deck transition via Storyboards
final class DeckSegue: UIStoryboardSegue {

    var transition: UIViewControllerTransitioningDelegate!

    override func perform() {
        transition = DeckTransitioningDelegate()
        destination.transitioningDelegate = transition
        destination.modalPresentationStyle = .custom
        source.present(destination, animated: true, completion: nil)
    }

}
