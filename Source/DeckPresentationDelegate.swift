//
//  DeckPresentationDelegate.swift
//  DeckTransition
//
//  Created by Reece Como on 15/9/18.
//  Copyright © 2018 Harshil Shah. All rights reserved.
//

import UIKit

/// Delegate methods provided by the drag
@objc
public protocol DeckPresentationDelegate {
    
    /// Is drag allowed?
    @objc optional func deckPresentationShouldAllowDragToBegin(_ panGestureRecognizer: UIPanGestureRecognizer) -> Bool
    
    /// Called when drag began
    @objc optional func deckPresentationDragDidBegin(_ panGestureRecognizer: UIPanGestureRecognizer)
    
    /// Called when drag ended
    @objc optional func deckPresentationDragDidEnd(_ panGestureRecognizer: UIPanGestureRecognizer, andViewControllerWillDismiss willDismiss: Bool)
    
    /// Called during drag
    @objc optional func deckPresentationDidDrag(_ panGestureRecognizer: UIPanGestureRecognizer, toPosition position: CGPoint)
    
}
