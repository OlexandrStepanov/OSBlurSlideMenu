//
//  BlurSlideMenuViewController.h
//  BlurSlideMenuViewController
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, OSBlurSlideMenuControllerSlideDirection)
{
    OSBlurSlideMenuControllerSlideFromLeftToRight = 0, // default, slide from left to right to open the menu
    OSBlurSlideMenuControllerSlideFromRightToLeft // slide from right to left to open the menu
};


@interface OSBlurSlideMenuController : UIViewController

@property (nonatomic, readonly) UIViewController *menuViewController;
@property (nonatomic, readonly) UIViewController *contentViewController;
@property (nonatomic, assign) BOOL panGestureEnabled; // default is YES. Set it to NO to disable the pan gesture
@property (nonatomic, assign) CGFloat menuWidth; // default is 276

- (id)initWithMenuViewController:(UIViewController *)menuViewController
        andContentViewController:(UIViewController *)contentViewController;

/** @name Navigation */
- (IBAction)toggleMenuAnimated:(id)sender; // Convenience for use with target/action, always animate

- (void)openMenuAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)closeMenuAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion;
- (void)closeMenuBehindContentViewController:(UIViewController *)contentViewController animated:(BOOL)animated completion:(void(^)(BOOL finished))completion;

/** @name Slide direction */
@property (nonatomic, assign) OSBlurSlideMenuControllerSlideDirection slideDirection;

/** @name Menu state information */
- (BOOL)isMenuOpen;

@end


#pragma mark - UIViewController (OSBlurSlideMenuController)

@interface UIViewController (OSBlurSlideMenuController)

@property (nonatomic, readonly) OSBlurSlideMenuController *slideMenuController;

@end


#pragma mark - UIViewController (OSBlurSlideMenuControllerCallbacks)

/**
 Subclasses may override these methods to perform custom actions (such as disable interaction with a web view or a table view)
 when they slide in our out.
 These callbacks are only called on the contentViewController of the slideMenuController.
 */
@interface UIViewController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController; // default implementation does nothing
- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController; // default implementation does nothing
- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController; // default implementation does nothing
- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController; // default implementation does nothing

@end

