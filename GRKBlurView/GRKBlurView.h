//
//  GRKBlurView.h
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

#import <UIKit/UIKit.h>

@interface GRKBlurView : UIView

/**
 The base image to apply effects to.
 @note Setting this property will initiate an `update`.
 */
@property (nonatomic,strong) UIImage *targetImage;
/**
 The radius of the blur to apply. 0 is no blur, while 30 (for example) is quite blurred.
 @note The `update` message needs to be sent for changes to this property to be rendered.
 */
@property (nonatomic,assign) CGFloat blurRadius;
/**
 A color to apply as a tint to the image. This color can have an alpha to lessen the tint, or can be nil.
 @note The `update` message needs to be sent for changes to this property to be rendered.
 */
@property (nonatomic,strong) UIColor *tintColor;
/**
 Changes the saturation of the image. The default value is 1.0 (no change). To add saturation a value like 1.8 is a good reference.
 @note The `update` message needs to be sent for changes to this property to be rendered.
 */
@property (nonatomic,assign) CGFloat saturationDeltaFactor;
/**
 An image to use as a mask to the applied affects. Can be nil (default).
 @note Setting this property will initiate an `update`.
 */
@property (nonatomic,strong) UIImage *maskImage;

/**
 *  Grabs a snapshot of the given view, uses it as the target image, and performs an update.
 *
 *  @param targetView A UIView instance which will render into an image which will be set as the targetImage.
 *  @see targetImage
 *  @see update
 */
- (void)setTargetImageFromView:(UIView *)targetView;

/**
 Render and apply the various effects. This will be performed asynchronously.
 @see updateBlurRadiusFromPercent:ofMax:
 */
- (void)update;

/**
 Renders and applies the various effects while also augmenting the `blurRadius` based on the given values.
 This is a convenience method which allows the caller to change the blur based on a percentage of some max value.
 If the percent value has not changed since the last call, no update will occur (even if other properties have changed).
 @param percent       A value between 0 and 1 representing the percentage of `maxBlurRadius` to apply as the `blurRadius`.
 @param maxBlurRadius The maximum blur radius.
 @see blurRadius
 @see update
 */
- (void)updateBlurRadiusFromPercent:(CGFloat)percent ofMax:(CGFloat)maxBlurRadius;

@end
