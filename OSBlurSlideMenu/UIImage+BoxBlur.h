//
//  UIImage+BoxBlur.h
//  LiveBlurView
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface UIImage (BoxBlur)

- (UIImage *)blurredImageWithRadius:(CGFloat)radius iterations:(NSUInteger)iterations tintColor:(UIColor *)tintColor
                          blendMode:(CGBlendMode)tintColorBlendMode;
@end
