//
//  GRKBlurView.m
//
//  Created by Levi Brown on January 8, 2014.
//  Copyright (c) 2014 Levi Brown <mailto:levigroker@gmail.com>
//  This work is licensed under the Creative Commons Attribution 3.0
//  Unported License. To view a copy of this license, visit
//  http://creativecommons.org/licenses/by/3.0/ or send a letter to Creative
//  Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041,
//  USA.
//
//  The above attribution and the included license must accompany any version
//  of the source code. Visible attribution in any binary distributable
//  including this work (or derivatives) is not required, but would be
//  appreciated.
//

#import "GRKBlurView.h"
#import "UIImage+Blur.h"
#import "UIImage+Resize.h"
#import "UIView+Snapshot.h"

@interface GRKBlurView ()

@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) NSOperationQueue *updateQueue;
@property (atomic,strong) UIImage *scaledImage;
@property (atomic,strong) UIImage *scaledMaskImage;

@end

@implementation GRKBlurView

#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
    {
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self setup];
    }
    return self;
}

- (void)setup
{
    //Defaults
    self.saturationDeltaFactor = 1.0f;
    
    //Add an image view to hold the effects image
    UIImageView *imageView = [[UIImageView alloc] initWithImage:nil];
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self insertSubview:imageView atIndex:0];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[imageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[imageView]|" options:0 metrics:nil views:NSDictionaryOfVariableBindings(imageView)]];
    self.imageView = imageView;
}

#pragma mark - Layout

- (void)layoutSubviews
{
    [super layoutSubviews];

    self.scaledImage = nil;
    self.scaledMaskImage = nil;
    [self update];
}

#pragma mark - Accessors

- (void)setTargetImage:(UIImage *)targetImage
{
    _targetImage = targetImage;
    self.scaledImage = nil;
    [self update];
}

- (void)setMaskImage:(UIImage *)maskImage
{
    _maskImage = maskImage;
    self.scaledMaskImage = nil;
    [self update];
}

#pragma mark - API Implementation

- (void)setTargetImageFromView:(UIView *)targetView
{
    UIImage *image = [targetView snapshot];
    self.targetImage = image;
}

- (void)update
{
    if (!self.updateQueue)
    {
        self.updateQueue = [[NSOperationQueue alloc] init];
        //We only want one operation at a time
        [self.updateQueue setMaxConcurrentOperationCount:1];
    }
    
    //Cancel all outstanding operations (has no effect on the currently processing operation)
    [self.updateQueue cancelAllOperations];
    
    //Capture needed data for our operation
    UIImage *targetImage = self.targetImage;
    __block UIImage *scaledImage = self.scaledImage;
    UIImage *maskImage = self.maskImage;
    __block UIImage *scaledMaskImage = self.scaledMaskImage;
    CGFloat blurRadius = self.blurRadius;
    UIColor *tintColor = self.tintColor;
    CGFloat saturationDeltaFactor = self.saturationDeltaFactor;
    CGSize curentSize = self.bounds.size;
    __weak GRKBlurView *weakSelf = self;
    
    //Add our new update operation
    [self.updateQueue addOperationWithBlock:^{
        //Scale the target image to our size, as needed, rather than apply the blur to a differently sized image.
        if (!scaledImage && targetImage)
        {
            CGSize targetImageSize = targetImage.size;
            if (CGSizeEqualToSize(targetImageSize, curentSize))
            {
                scaledImage = targetImage;
            }
            else
            {
                scaledImage = [targetImage imageScaledToSize:curentSize];
            }
        }
        //Scale the mask image to our size, as needed, rather than apply the blur to a differently sized image.
        if (!scaledMaskImage && maskImage)
        {
            CGSize maskImageSize = maskImage.size;
            if (CGSizeEqualToSize(maskImageSize, curentSize))
            {
                scaledMaskImage = maskImage;
            }
            else
            {
                scaledMaskImage = [maskImage imageScaledToSize:curentSize];
            }
        }
        //Perform the effects
        UIImage *effectImage = [scaledImage applyBlurWithRadius:blurRadius tintColor:tintColor saturationDeltaFactor:saturationDeltaFactor maskImage:scaledMaskImage];
        //Jump to the main quque for our UI update
        dispatch_async(dispatch_get_main_queue(), ^{
            _targetImage = targetImage; //Must not use property setter here, as it will cause infinite loop
            weakSelf.scaledImage = scaledImage;
            weakSelf.scaledMaskImage = scaledMaskImage;
            weakSelf.imageView.image = effectImage;
        });
    }];
}

- (void)updateBlurRadiusFromPercent:(CGFloat)percent ofMax:(CGFloat)maxBlurRadius
{
    static CGFloat previousRadius = -1;
    CGFloat radius = MAX(0, MIN(percent * maxBlurRadius, maxBlurRadius));
    if (radius != previousRadius)
    {
        previousRadius = radius;
        self.blurRadius = radius;
        [self update];
    }
}

@end
