//
//  BlurredView.m
//  BlurSlideMenuDemo
//
//  Created by Alexandr Stepanov on 25.04.14.
//  Copyright (c) 2014 StartApp. All rights reserved.
//

#import "OSBlurredView.h"
#import "UIImage+StackBlur.h"

@interface OSBlurredView() {
    dispatch_queue_t _bluringQueue;
}

@property (nonatomic, strong) UIImage *superviewSnapshot;
@property (nonatomic, strong) UIImageView *imageView;
@property (atomic, readwrite) BOOL updatingBlur;

+ (dispatch_queue_t)blurringQueue;

@end

@implementation OSBlurredView

+ (dispatch_queue_t)blurringQueue {
    static dispatch_once_t onceToken;
    static dispatch_queue_t instance;
    dispatch_once(&onceToken, ^{
        instance = dispatch_queue_create("blurring_queue", nil);
    });
    return instance;
}

#pragma mark Initialization

- (void)setUp {
    self.blurLevel = 20.0f;
    
    self.backgroundColor = [UIColor clearColor];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.backgroundColor = [UIColor clearColor];
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:self.imageView];
}

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self setUp];
        self.clipsToBounds = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder])) {
        [self setUp];
    }
    return self;
}


#pragma mark - Snapshot stuff

- (void)createSnapshot {
    if (self.superview) {
        self.superviewSnapshot = [self snapshotOfSuperview:self.superview];
        self.imageView.image = self.superviewSnapshot;
    }
}

- (UIImage *)snapshotOfSuperview:(UIView *)superview
{
    CGFloat scale = 1.0;
//    if (self.iterations > 0 && ([UIScreen mainScreen].scale > 1 || self.contentMode == UIViewContentModeScaleAspectFill)) {
//        CGFloat blockSize = 12.0f/self.iterations;
//        scale = blockSize/MAX(blockSize * 2, floor(self.blurRadius));
//    }
    CGSize size = self.bounds.size;
    size.width = ceilf(size.width * scale) / scale;
    size.height = ceilf(size.height * scale) / scale;
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, YES, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetRGBFillColor(context, 1, 1, 1, 1);
    CGContextFillRect(context, self.bounds);
    CGContextTranslateCTM(context, -self.frame.origin.x, -self.frame.origin.y);
    CGContextScaleCTM(context, size.width / self.bounds.size.width, size.height / self.bounds.size.height);
    NSArray *hiddenViews = [self prepareSuperviewForSnapshot:superview];
    [superview.layer renderInContext:context];
    [self restoreSuperviewAfterSnapshot:hiddenViews];
    if (self.drawWhiteCover) {
        CGContextSetRGBFillColor(context, 1, 1, 1, 0.85f);
        CGContextFillRect(context, CGRectInset(self.frame, -100, -100));
    }
    UIImage *snapshot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return snapshot;
}

- (NSArray *)prepareSuperviewForSnapshot:(UIView *)superview
{
    NSMutableArray *views = [NSMutableArray array];
    NSInteger index = [superview.subviews indexOfObject:self];
    if (index != NSNotFound)
    {
        for (NSUInteger i = index; i < [superview.subviews count]; i++)
        {
            UIView *view = superview.subviews[i];
            if (!view.hidden)
            {
                view.hidden = YES;
                [views addObject:view];
            }
        }
    }
    return views;
}

- (void)restoreSuperviewAfterSnapshot:(NSArray *)hiddenViews
{
    for (UIView *view in hiddenViews)
    {
        view.hidden = NO;
    }
}

#pragma mark - Blurring

- (void)forceUpdate:(BOOL)forceFlag blurWithDegree:(CGFloat)degree {
    if (forceFlag || !self.updatingBlur) {
        NSLog(@"updating blur with degree = %f", degree);
        self.updatingBlur = YES;
        dispatch_async([OSBlurredView blurringQueue], ^{
            UIImage *blurredImage = [self.superviewSnapshot stackBlur:(degree * self.blurLevel) tintColor:self.blurTintColor];
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = blurredImage;
                self.imageView.alpha = MIN(degree*2.5f, 1.f);
                self.updatingBlur = NO;
            });
        });
    }
}


@end
