//
//  BlurredView.h
//  BlurSlideMenuDemo
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OSBlurredView : UIView

@property (nonatomic, strong) UIColor *blurTintColor;   //  default nil
@property (nonatomic) CGFloat blurLevel;    //  Default 20.0
@property (nonatomic) BOOL drawWhiteCover;

- (void)createSnapshot;
- (void)updateBlurWithDegree:(CGFloat)degree;

@end
