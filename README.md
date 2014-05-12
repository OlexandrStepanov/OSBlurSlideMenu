# OSBlurSlideMenu

iOS slide menu view controller with blurring effect.
Inspired by http://vimeo.com/69072524.


## Requirements

* Xcode 5 or higher
* Apple LLVM compiler
* iOS 6.0 or higher
* ARC


## Demo

Build and run the `OSBlurSlideMenuDemo` project in Xcode to see `OSBlurSlideMenu` in action.


## Installation

All you need to do is drop `RESideMenu` files into your project, and add `#import "OSBlurSlideMenu.h"` to the top of classes that will use it.


## Example Usage

The main class to use is `OSBlurSlideMenuController`.
Method for initialization:

``` objective-c
- (id)initWithMenuViewController:(UIViewController *)menuViewController andContentViewController:(UIViewController *)contentViewController
```
Refer to OSBlurSlideMenuDemo for live sample of usage.


# Acknowledgements
For blurring used stack blur from https://github.com/tomsoft1/StackBluriOS.


## License

RESideMenu is available under the Apache v2.0 license.
Refer to LICENSE file for details.

Copyright © 2014 Oleksandr Stepanov.
