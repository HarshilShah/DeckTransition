# `UIScrollView` Detection

This guide explains various DeckTransitionʼs `UIScrollView` detection heuristic, some edge cases, and how these can be worked around.

## How It Works

In keeping with the style used in Apple Musicʼs iOS app, DeckTransition has a fluid swipe-to-dismiss gesture.

In order to activate this, you just need to swipe down on the card. If there is a `UIScrollView` within the card, the gesture is activated as soon as the scroll view is scrolled to the very top. This is a fluid gesture: The same pan used to scroll the scroll view to the top can be continued to dismiss the modal without starting a new touch, so it’s important for DeckTransition to detect the main scroll view of your view hierarchy.

DeckTransition’s internal methodology to detect which `UIScrollView` has two parts:
1. Detecting the UIViewController instance which should contain the `UIScrollView`.
2. Detecting the `UIScrollView` instance within it.

## Detecting The `UIViewController`

The view controller presented using DeckTransition itself may not contain the `UIScrollView` instance which needs to be tracked for a dismiss gesture.

You may be using containment to better organise your code, in which case you can conform your view controllers to `DeckTransitionViewControllerProtocol` and implement the `childViewControllerForDeck` variable to return the child view controller which contains the `UIScrollView` instance to be tracked. This works with nested containment as well.

DeckTransition will traverse your view hierarchy until it reaches a `UIViewController` which either doesn’t conform to the protocol, or returns `nil`. The view controller reached at the end of this search process will be further searched for the `UIScrollView` instance to track.

## Detecting the `UIScrollView`

Once the view controller is correctly identified, DeckTransition searches its view’s top-level subviews (i.e. `viewController.view.subviews`), and by default uses the lowermost `UIScrollView` instance, if one is found.

However this may not always find the `UIScrollView` instance you may want it to, in which case you can conform your view controllers to `DeckTransitionViewControllerProtocol` and implement the `scrollViewForDeck` variable to return `UIScrollView` instance to be tracked.
