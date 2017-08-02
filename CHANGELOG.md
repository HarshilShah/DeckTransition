## Changelog

0.4.0 Release notes (2/8/2017)
----

### API Breaking Changes
- The `DeckTransitioningDelegate` initialiser now requires `NSNumber` arguments for animation duration
- A snapshot of the presenting view controller is shown instead of the view itself

### Other Changes
- Fixed Objective-C compatibility issues
- Fixed a host of bugs related to the double height status bar and rotation
- You can now use `pod try` to try the library

0.3.0 Release notes (14/5/2017)
----

- The transition can now be customised by passing in custom animation durations, other animations to be performed alongside the stock animation, and completion handlers

0.2.0 Release notes (5/3/2017)
----

- Made the dismissal gesture friction more realistic

0.1.2 Release notes (27/2/2017)
----

- Fixed an issue where touches to the presented view were being delayed

0.1.1 Release notes (2/12/2016)
----

- Fixed an issue which may prevent masking for the presenting view controller
- Made the example application universal and added icons

0.1.0 Release notes (18/10/2016)
----

- Initial release
