//
//  BlurSlideMenuViewController.m
//  BlurSlideMenuViewController
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "OSBlurSlideMenuController.h"
#import "OSBlurredView.h"


#define kBlurMaximumRadius 10.f
#define kSlideAnimationDuration 0.3f

@interface OSBlurSlideMenuController ()
{
	CGFloat _contentViewWidthWhenMenuIsOpen;
}

/** Children view controllers */
@property (nonatomic, strong) UIViewController *menuViewController;
@property (nonatomic, strong) UIViewController *contentViewController;

/** Blur view */
@property (nonatomic, strong) OSBlurredView *blurView;

/**
 Load the menu view controller view and add its view as a subview
 to self.view with correct frame.
 */
- (void)loadMenuViewControllerViewIfNeeded;

/** Gesture recognizers */
@property (nonatomic, strong) UITapGestureRecognizer *tapGesture;
- (void)tapGestureTriggered:(UITapGestureRecognizer *)tapGesture;

@property (nonatomic, assign) CGRect contentViewControllerFrame;
@property (nonatomic, assign) BOOL menuWasOpenAtPanBegin;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;
- (void)panGestureTriggered:(UIPanGestureRecognizer *)panGesture;

/** Utils */
- (CGRect)frameForBlurView;
- (CGRect)frameForMenuView;
- (CGRect)frameForMenuViewDisappeared;
- (UIViewAutoresizing)menuViewAutoresizingMaskAccordingToCurrentSlideDirection;


@end


@implementation OSBlurSlideMenuController

#pragma mark Initializers

- (id)initWithMenuViewController:(UIViewController *)menuViewController andContentViewController:(UIViewController *)contentViewController
{
	self = [super initWithNibName:nil bundle:nil];
	if (self)
	{
		self.menuViewController = menuViewController;
		self.contentViewController = contentViewController;
		self.panGestureEnabled = YES;
        self.slideDirection = OSBlurSlideMenuControllerSlideFromLeftToRight;
		_contentViewWidthWhenMenuIsOpen = -1;
		self.menuWidth = 276;
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder:aDecoder];
	if (self)
	{
		self.menuViewController = nil;
		self.contentViewController = nil;
		self.panGestureEnabled = YES;
        self.slideDirection = OSBlurSlideMenuControllerSlideFromLeftToRight;
        _contentViewWidthWhenMenuIsOpen = -1;
		self.menuWidth = 276;
	}
	
	return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [self initWithMenuViewController:nil andContentViewController:nil];
}


#pragma mark - Children View Controllers

- (void)setMenuViewController:(UIViewController *)menuViewController
{
	if (menuViewController != _menuViewController) {
		[_menuViewController willMoveToParentViewController:nil];
		[_menuViewController removeFromParentViewController];
		_menuViewController = menuViewController;
	}
}

- (void)setContentViewController:(UIViewController *)contentViewController
{
	if (contentViewController != _contentViewController) {
		[_contentViewController willMoveToParentViewController:nil];
		[_contentViewController removeFromParentViewController];
		_contentViewController = contentViewController;
	}
}


#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	if (_contentViewWidthWhenMenuIsOpen >= 0) {
		self.menuWidth = CGRectGetWidth(self.view.bounds) - _contentViewWidthWhenMenuIsOpen;
    }
    
    [self addChildViewController:self.contentViewController];
	self.contentViewController.view.frame = self.view.bounds;
	[self.view addSubview:self.contentViewController.view];
	[self.contentViewController didMoveToParentViewController:self];
	   
    self.blurView = [[OSBlurredView alloc] initWithFrame:[self frameForBlurView]];
    self.blurView.blurTintColor = [UIColor colorWithWhite:0.85 alpha:1.0];
    
    [self.blurView addGestureRecognizer:self.tapGesture];
    [self configurePanGesture];
    
    [self loadMenuViewControllerViewIfNeeded];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
    
    if (![self isMenuOpen])
		self.contentViewController.view.frame = self.view.bounds;
	
	[self.contentViewController beginAppearanceTransition:YES animated:animated];
	if ([self.menuViewController isViewLoaded] && self.menuViewController.view.superview)
		[self.menuViewController beginAppearanceTransition:YES animated:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
    [self.contentViewController endAppearanceTransition];
	if ([self.menuViewController isViewLoaded] && self.menuViewController.view.superview)
		[self.menuViewController endAppearanceTransition];
}


- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	
    [self.contentViewController beginAppearanceTransition:NO animated:animated];
	if ([self.menuViewController isViewLoaded])
		[self.menuViewController beginAppearanceTransition:NO animated:animated];
}


- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	
    [self.contentViewController endAppearanceTransition];
	if ([self.menuViewController isViewLoaded])
		[self.menuViewController endAppearanceTransition];
}


#pragma mark - Appearance & rotation callbacks

- (BOOL)shouldAutomaticallyForwardAppearanceMethods
{
	return NO;
}


- (BOOL)shouldAutomaticallyForwardRotationMethods
{
	return YES;
}


- (BOOL)automaticallyForwardAppearanceAndRotationMethodsToChildViewControllers
{
	return NO;
}


#pragma mark - Rotation

- (BOOL)shouldAutorotate
{
	return	[self.menuViewController shouldAutorotate] &&
			[self.contentViewController shouldAutorotate] &&
			self.panGesture.state != UIGestureRecognizerStateChanged;
}


- (NSUInteger)supportedInterfaceOrientations
{
	return [self.menuViewController supportedInterfaceOrientations] & [self.contentViewController supportedInterfaceOrientations];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return	[self.menuViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation] &&
			[self.contentViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

//- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
//	[super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
//	
//	if ([self isMenuOpen]) {
//		CGRect frame = self.contentViewController.view.frame;
//		frame.origin.x = [self contentViewMinX];
//		self.contentViewController.view.frame = frame;
//	}
//}

#pragma mark - Menu view lazy load

- (void)loadMenuViewControllerViewIfNeeded
{
	if (!self.menuViewController.view.window)
	{
		[self addChildViewController:self.menuViewController];
        self.menuViewController.view.frame = [self frameForMenuViewDisappeared];
		self.menuViewController.view.autoresizingMask = [self menuViewAutoresizingMaskAccordingToCurrentSlideDirection];
		[self.view insertSubview:self.menuViewController.view aboveSubview:self.blurView];
		[self.menuViewController didMoveToParentViewController:self];
	}
}


#pragma mark - Navigation

- (IBAction)toggleMenuAnimated:(id)sender
{
	if ([self isMenuOpen])
		[self closeMenuAnimated:YES completion:nil];
	else
		[self openMenuAnimated:YES completion:nil];
}


- (void)openMenuAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
	NSTimeInterval duration = animated ? kSlideAnimationDuration : 0;
    
    [self showHideBlurView:YES];
		
	[self.menuViewController beginAppearanceTransition:YES animated:animated];
	[self.contentViewController viewWillSlideOut:animated inSlideMenuController:self];
	
    self.blurView.alpha = 0.0;
    [self.blurView updateBlurWithDegree:1.0f];
	[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.blurView.alpha = 1.0;
		self.menuViewController.view.frame = [self frameForMenuView];
	} completion:^(BOOL finished) {
		[self.menuViewController endAppearanceTransition];
		[self.contentViewController viewDidSlideOut:animated inSlideMenuController:self];
		
        [self configurePanGesture];
        
		if (completion)
			completion(finished);
	}];
}


- (void)closeMenuAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
	// Remove gestures
//	self.tapGesture.enabled = NO;
    
    NSTimeInterval duration = animated ? kSlideAnimationDuration : 0;
    
	[self.menuViewController beginAppearanceTransition:NO animated:animated];
	[self.contentViewController viewWillSlideIn:animated inSlideMenuController:self];
	
	[UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        self.blurView.alpha = 0.f;
        self.menuViewController.view.frame = [self frameForMenuViewDisappeared];
	} completion:^(BOOL finished) {
		[self.menuViewController endAppearanceTransition];
		[self.contentViewController viewDidSlideIn:animated inSlideMenuController:self];
		
        [self showHideBlurView:NO];
        [self configurePanGesture];
		
		if (completion)
			completion(finished);
	}];
}


- (void)closeMenuBehindContentViewController:(UIViewController *)contentViewController
                                    animated:(BOOL)animated
                                  completion:(void(^)(BOOL finished))completion
{	
    NSAssert(contentViewController != nil, @"Can't show a nil content view controller.");
    
    void (^swapContentViewController)() = nil;

	if (contentViewController != self.contentViewController) {
        swapContentViewController = ^{
            // Preserve the frame
            CGRect frame = self.contentViewController.view.frame;
            
            // Remove old content view
            [self.contentViewController.view removeGestureRecognizer:self.panGesture];
            
            [self.contentViewController beginAppearanceTransition:NO animated:NO];
            
            [self.contentViewController willMoveToParentViewController:nil];
            [self.contentViewController.view removeFromSuperview];
            [self.contentViewController removeFromParentViewController];
            
            [self.contentViewController endAppearanceTransition];
        
            // Add the new content view
            self.contentViewController = contentViewController;
            self.contentViewController.view.frame = frame;
            [self.contentViewController.view addGestureRecognizer:self.panGesture];
            
            [self.contentViewController beginAppearanceTransition:YES animated:NO];
            [self addChildViewController:self.contentViewController];
            [self.view addSubview:self.contentViewController.view];
            [self.contentViewController didMoveToParentViewController:self];
            [self.contentViewController endAppearanceTransition];
        };
	}
    
    if (swapContentViewController) {
        swapContentViewController();
    }
	
	if ([self isMenuOpen]) {
        [self closeMenuAnimated:animated completion:completion];
    }
}


#pragma mark - Gestures

- (UITapGestureRecognizer *)tapGesture
{
	if (!_tapGesture) {
		_tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureTriggered:)];
    }
	
	return _tapGesture;
}


- (void)tapGestureTriggered:(UITapGestureRecognizer *)tapGesture
{
	if (tapGesture.state == UIGestureRecognizerStateEnded) {
		[self closeMenuAnimated:YES completion:nil];
    }
}


- (UIPanGestureRecognizer *)panGesture
{
	if (!_panGesture) {
		_panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureTriggered:)];
        _panGesture.maximumNumberOfTouches = 1;
    }
	
	return _panGesture;
}


- (void)setPanGestureEnabled:(BOOL)panGestureEnabled
{
	self.panGesture.enabled = panGestureEnabled;
}


- (BOOL)panGestureEnabled
{
	return self.panGesture.enabled;
}


- (void)panGestureTriggered:(UIPanGestureRecognizer *)panGesture
{
	if (panGesture.state == UIGestureRecognizerStateBegan)
	{
		self.menuWasOpenAtPanBegin = [self isMenuOpen];
		
		if (self.menuWasOpenAtPanBegin) {
            [self.contentViewController viewWillSlideIn:YES inSlideMenuController:self];
		}
		else {
            [self.contentViewController viewWillSlideOut:YES inSlideMenuController:self]; // Content view controller is sliding out
		}
        
        [self showHideBlurView:YES];
	}
	
	CGPoint translation = [panGesture translationInView:panGesture.view];
    CGFloat blurDegree = translation.x / self.view.bounds.size.width;
    if (self.menuWasOpenAtPanBegin) {
        blurDegree *= -1.f;
    }
    blurDegree = MIN(MAX(blurDegree, 0.0), 1.0);
    if (self.menuWasOpenAtPanBegin) {
        blurDegree = 1.f - blurDegree;
    }
    NSLog(@"blurRadius: %f", blurDegree);
    [self.blurView updateBlurWithDegree:blurDegree];
    
    if (self.menuWasOpenAtPanBegin) {
        CGRect startFrame = [self frameForMenuView];
        CGRect endFrame = [self frameForMenuViewDisappeared];
        
        CGRect menuFrame = startFrame;
        menuFrame.origin.x = (1.f - blurDegree) * endFrame.origin.x + blurDegree * startFrame.origin.x;
        self.menuViewController.view.frame = menuFrame;
    }
	
	if (panGesture.state == UIGestureRecognizerStateEnded)
	{
		NSTimeInterval animationDuration = 0.1;
        BOOL changeState;
        if (self.menuWasOpenAtPanBegin) {
            changeState = blurDegree < 0.5f;
            if (!changeState) {
                CGPoint velocity = [panGesture velocityInView:panGesture.view];
                if (self.slideDirection == OSBlurSlideMenuControllerSlideFromLeftToRight)
                    changeState = (velocity.x < 0);
                else
                    changeState = (velocity.x > 0);
            }
        }
        else {
            changeState = blurDegree > 0.5f;
        }
				
		if (changeState)
		{
			if (self.menuWasOpenAtPanBegin)
			{
                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.menuViewController.view.frame = [self frameForMenuViewDisappeared];
                } completion:^(BOOL finished) {
                    [self.menuViewController endAppearanceTransition];
                    [self.contentViewController viewDidSlideIn:YES inSlideMenuController:self];
                    
                    [self showHideBlurView:NO];
                    [self configurePanGesture];
                    
                    self.tapGesture.enabled = NO;
                }];
			}
            else {
                [self.blurView updateBlurWithDegree:1.f];
                
                [self.menuViewController beginAppearanceTransition:NO animated:YES];
                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.menuViewController.view.frame = [self frameForMenuView];
                } completion:^(BOOL finished) {
                    [self.menuViewController endAppearanceTransition];
                    [self.contentViewController viewDidSlideOut:YES inSlideMenuController:self];
                    self.tapGesture.enabled = YES;
                    [self configurePanGesture];
                }];
            }
		}
		else
		{
			if (self.menuWasOpenAtPanBegin)
			{
                [self.blurView updateBlurWithDegree:1.f];

                [UIView animateWithDuration:animationDuration delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    self.menuViewController.view.frame = [self frameForMenuView];
                } completion:^(BOOL finished) {
                    [self.menuViewController endAppearanceTransition];
                    [self.contentViewController viewDidSlideOut:YES inSlideMenuController:self];
                    self.tapGesture.enabled = YES;
                    [self configurePanGesture];
                }];
			}
            else {
                self.menuViewController.view.frame = [self frameForMenuViewDisappeared];
                [self showHideBlurView:NO];
                [self configurePanGesture];
            }
		}
	}
}

- (void)configurePanGesture {
    if (self.blurView.superview) {
        [self.contentViewController.view removeGestureRecognizer:self.panGesture];
        [self.menuViewController.view addGestureRecognizer:self.panGesture];
    }
    else {
        [self.menuViewController.view removeGestureRecognizer:self.panGesture];
        [self.contentViewController.view addGestureRecognizer:self.panGesture];
    }
}


#pragma mark - Menu State

- (BOOL)isMenuOpen
{
	return CGRectEqualToRect(self.menuViewController.view.frame, [self frameForMenuView]);
}


#pragma mark - Utils

- (void)showHideBlurView:(BOOL)show {
    if (show) {
        if (self.blurView.superview) {
            [self.blurView removeFromSuperview];
        }
        [self.view insertSubview:self.blurView belowSubview:self.menuViewController.view];
        self.blurView.alpha = 1.f;
        [self.blurView createSnapshot];
    }
    else {
        [self.blurView removeFromSuperview];
    }
}

- (CGRect)frameForBlurView {
    CGRect result = self.view.bounds;
    
    return result;
}

- (CGRect)frameForMenuView {
    CGRect result = [self frameForBlurView];
    if (self.slideDirection == OSBlurSlideMenuControllerSlideFromRightToLeft) {
        result.origin.x = result.size.width - self.menuWidth;
    }
    result.size.width = self.menuWidth;
    
    return result;
}

- (CGRect)frameForMenuViewDisappeared {
    CGRect result = [self frameForMenuView];
    if (self.slideDirection == OSBlurSlideMenuControllerSlideFromLeftToRight) {
        result.origin.x -= result.size.width;
    }
    else {
        result.origin.x += result.size.width;
    }

    return result;
}

- (UIViewAutoresizing)menuViewAutoresizingMaskAccordingToCurrentSlideDirection
{
	UIViewAutoresizing resizingMask = UIViewAutoresizingFlexibleHeight;
	
	if (self.slideDirection == OSBlurSlideMenuControllerSlideFromLeftToRight)
		resizingMask = resizingMask | UIViewAutoresizingFlexibleRightMargin;
	else
		resizingMask = resizingMask | UIViewAutoresizingFlexibleLeftMargin;
	
	return resizingMask;
}

@end


#pragma mark -
#pragma mark - UIViewController (OSBlurSlideMenuController)

@implementation UIViewController (OSBlurSlideMenuController)

- (OSBlurSlideMenuController *)slideMenuController
{
	OSBlurSlideMenuController *slideMenuController = nil;
	UIViewController *parentViewController = self.parentViewController;
	
	while (!slideMenuController && parentViewController)
	{
		if ([parentViewController isKindOfClass:[OSBlurSlideMenuController class]])
			slideMenuController = (OSBlurSlideMenuController*)parentViewController;
		else
			parentViewController = parentViewController.parentViewController;
	}
	
	return slideMenuController;
}

@end

#pragma mark - UIViewController (OSBlurSlideMenuControllerCallbacks)

@implementation UIViewController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController {
	// default implementation does nothing
}


- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController {
    // default implementation does nothing
}


- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController {
	// default implementation does nothing
}


- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController {
	// default implementation does nothing
}

@end


#pragma mark - 
#pragma mark Private Categories

#pragma mark UINavigationController (OSBlurSlideMenuControllerCallbacks)

@interface UINavigationController (OSBlurSlideMenuControllerCallbacks)
// Forward callbacks to the topViewController
@end

@implementation UINavigationController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.topViewController viewWillSlideIn:animated inSlideMenuController:slideMenuController];
}


- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.topViewController viewDidSlideIn:animated inSlideMenuController:slideMenuController];
}


- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.topViewController viewWillSlideOut:animated inSlideMenuController:slideMenuController];
}


- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.topViewController viewDidSlideOut:animated inSlideMenuController:slideMenuController];
}

@end


#pragma mark UISplitViewController (OSBlurSlideMenuControllerCallbacks)

@interface UISplitViewController (OSBlurSlideMenuControllerCallbacks)
// Forward callbacks to the viewControllers
@end

@implementation UISplitViewController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewWillSlideIn:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewDidSlideIn:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewWillSlideOut:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewDidSlideOut:animated inSlideMenuController:slideMenuController];
	}];
}

@end


#pragma mark UITabBarController (OSBlurSlideMenuControllerCallbacks)

@interface UITabBarController (OSBlurSlideMenuControllerCallbacks)
// Forward callbacks to the selectedViewController
@end

@implementation UITabBarController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.selectedViewController viewWillSlideIn:animated inSlideMenuController:slideMenuController];
}


- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.selectedViewController viewDidSlideIn:animated inSlideMenuController:slideMenuController];
}


- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.selectedViewController viewWillSlideOut:animated inSlideMenuController:slideMenuController];
}


- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.selectedViewController viewDidSlideOut:animated inSlideMenuController:slideMenuController];
}

@end


#pragma mark UIPageViewController (OSBlurSlideMenuControllerCallbacks)

@interface UIPageViewController (OSBlurSlideMenuControllerCallbacks)
// Forward callbacks to the viewControllers
@end

@implementation UIPageViewController (OSBlurSlideMenuControllerCallbacks)

- (void)viewWillSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewWillSlideIn:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewDidSlideIn:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewDidSlideIn:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewWillSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewWillSlideOut:animated inSlideMenuController:slideMenuController];
	}];
}


- (void)viewDidSlideOut:(BOOL)animated inSlideMenuController:(OSBlurSlideMenuController *)slideMenuController
{
	[self.viewControllers enumerateObjectsUsingBlock:^(UIViewController *vc, NSUInteger idx, BOOL *stop) {
		[vc viewDidSlideOut:animated inSlideMenuController:slideMenuController];
	}];
}

@end
