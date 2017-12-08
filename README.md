# DeckTransition

[![CI Status](http://img.shields.io/travis/HarshilShah/DeckTransition.svg)](https://travis-ci.org/HarshilShah/DeckTransition)
[![Version](https://img.shields.io/github/release/HarshilShah/DeckTransition.svg)](https://github.com/HarshilShah/DeckTransition/releases/latest)
![Package Managers](https://img.shields.io/badge/supports-CocoaPods%20%7C%20Carthage-orange.svg)
[![Documentation](https://cdn.rawgit.com/HarshilShah/DeckTransition/master/docs/badge.svg)](https://harshilshah.github.com/DeckTransition)
[![License](https://img.shields.io/badge/license-MIT-999999.svg)](https://github.com/HarshilShah/DeckTransition/blob/master/LICENSE)
[![Contact](https://img.shields.io/badge/contact-%40HarshilShah1910-3a8fc1.svg)](https://twitter.com/HarshilShah1910)

DeckTransition is an attempt to recreate the card-like transition found in the iOS 10 Apple Music and iMessage apps.

Hereʼs a GIF showing it in action.

![Demo](https://raw.githubusercontent.com/HarshilShah/DeckTransition/master/Resources/demo.gif)

## Requirements

- Swift 4
- iOS 9 or later

## Installation

### CocoaPods

To install DeckTransition using [CocoaPods](http://cocoapods.org), add the following line to your Podfile:

```
pod 'DeckTransition', '~> 2.0'
```

### Carthage

To install DeckTransition using [Carthage](https://github.com/Carthage/Carthage), add the following line to your Cartfile:

```
github "HarshilShah/DeckTransition" ~> 2.0
```

## Documentation

You can find [the docs here](https://harshilshah.github.io/DeckTransition "Documentation"). Documentation is generated with [Jazzy](https://github.com/realm/jazzy), and hosted on [GitHub Pages](https://pages.github.com).

## Usage

### Basics

Set `modalPresentationCapturesStatusBarAppearance` to `true` in your modal view controller, and override the `preferredStatusBarStyle` variable to return `.lightContent`.

Additionally, the `UIScrollView` instances which should be tracked for the swipe-to-dismiss gesture should have their `backgroundColor` set to `.clear`.

### Presentation

The transition can be called from code or using a storyboard.

To use via storyboards, just setup a custom segue (`kind` set to `custom`), and set the `class` to `DeckSegue`.

Hereʼs a snippet showing usage via code. Just replace `ModalViewController()` with your view controller's class and youʼre good to go.

```swift
let modal = ModalViewController()
let transitionDelegate = DeckTransitioningDelegate()
modal.transitioningDelegate = transitionDelegate
modal.modalPresentationStyle = .custom
present(modal, animated: true, completion: nil)
```

### Dismissal

By default, DeckTransition has a swipe-to-dismiss gesture which is automatically enabled when your modalʼs main `UIScrollView` is scrolled to the top.

You can opt-out of this behaviour by passing in `false` for the `isSwipeToDismissEnabled` parameter while initialising your `DeckTransitioningDelegate`.

### `UIScrollView` detection

DeckTransition has an internal heuristic to determine which `UIScrollView` should be tracked for the swipe-to-dismiss gesture. In general, this should be sufficient for and cover most use cases.

However there are some edge cases, and should you run into one, these can we worked around by making your modal view controller conform to the `DeckTransitionViewControllerProtocol` protocol. More information about this can be found in the documentation page about [UIScrollView detection](https://harshilshah.github.io/DeckTransition/uiscrollview-detection.html).

### Snapshots

For a variety of reasons, and especially because of iOS 11's safe area layout, DeckTransition uses a snapshot of your presenting view controller's view instead of using the view directly. This view is automatically updated whenever the frame is resized.

However, there can be some cases where you might want to update the snapshot view by yourself, and this can be achieved using the following one line snippet:

```swift
(presentationController as? DeckSnapshotUpdater)?.requestPresentedViewSnapshotUpdate()
```

All this does is request the presentation controller to update the snapshot.

You can also choose to update snapshot directly from the presenting view controller, as follows:

```swift
(presentedViewController?.presentationController as? DeckSnapshotUpdater)?.requestPresentedViewSnapshotUpdate()
```

It's worth noting that updating the snapshot is an expensive process and should only be used if necessary, for example if you are updating your entire app's theme.

## Apps Using DeckTransition
- [Petty](https://zachsim.one/projects/petty) by [Zach Simone](https://twitter.com/zachsimone)
- [Bitbook](https://bitbookapp.com) by [Sammy Gutierrez](https://sammygutierrez.com)
- [BookPlayer](https://github.com/GianniCarlo/Audiobook-Player) by [Gianni Carlo](https://twitter.com/GCarlo89)

Feel free to submit a PR if you’re using this library in your apps

## Author

Written by [Harshil Shah](https://twitter.com/HarshilShah1910)

## License

DeckTransition is available under the MIT license. See the LICENSE file for more info.
