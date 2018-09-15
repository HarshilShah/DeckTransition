//
//  ModalViewController.swift
//  DeckTransition
//
//  Created by Harshil Shah on 15/10/16.
//  Copyright © 2016 Harshil Shah. All rights reserved.
//

import UIKit
import DeckTransition

class ModalViewController: UIViewController {

    let textView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        modalPresentationCapturesStatusBarAppearance = true
        
        view.backgroundColor = .white
        
        textView.isEditable = false
        textView.isSelectable = false
        textView.showsVerticalScrollIndicator = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 40, weight: .heavy)
        textView.textAlignment = .center
        textView.text = """
        This is the presented modal view controller.\n
        When youʼre scrolled to the very top of the view, you can swipe downwards to dismiss it.\n
        The swipe works in one fluid gesture if youʼre scrolling up as well.\n
        You can also tap again to present another modal
        """
        
        view.addSubview(textView)
        textView.topAnchor.constraint(equalTo: view.topAnchor, constant: 20).isActive = true
        textView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 20).isActive = true
        textView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -20).isActive = true
        textView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20).isActive = true
	
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.viewWasTapped))
        view.addGestureRecognizer(tap)
    }
    
    @objc func viewWasTapped() {
        let modal = ModalViewController()
        let transitionDelegate = DeckTransitioningDelegate()
        modal.transitioningDelegate = transitionDelegate
        modal.modalPresentationStyle = .custom
        present(modal, animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
	
}

extension ModalViewController: DeckPresentationDelegate {
    
    /// Is drag allowed?
    func deckPresentationShouldAllowDragToBegin(_: UIPanGestureRecognizer) -> Bool {
        return true
    }
    
    /// Called when drag began
    func deckPresentationDragDidBegin(_: UIPanGestureRecognizer) {
        print("starting drag")
    }
    
    /// Called when drag ended
    func deckPresentationDragDidEnd(_: UIPanGestureRecognizer, andViewControllerWillDismiss willDismiss: Bool) {
        if willDismiss {
            print("dismissing")
        } else {
            print("not dismissing")
        }
    }
    
    /// Called during drag
    func deckPresentationDidDrag(_: UIPanGestureRecognizer, toPosition position: CGPoint) {
        print("dragging")
    }
    
    
}
