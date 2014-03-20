//
//  GRKBlurView.m
//
//  Created by Levi Brown on January 8, 2014.
//  Copyright (c) 2013 Levi Brown <mailto:levigroker@gmail.com>
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
#import <float.h>
@import Accelerate;

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

@implementation UIImage (Blur)

/*
 Taken from Apple WWDC 2013 sample code, with minor modifications by Levi Brown.
 
 File: UIImage+ImageEffects.m
 Abstract: This is a category of UIImage that adds methods to apply blur and tint effects to an image.
 Version: 1.0
 */
- (UIImage *)applyBlurWithRadius:(CGFloat)blurRadius tintColor:(UIColor *)tintColor saturationDeltaFactor:(CGFloat)saturationDeltaFactor maskImage:(UIImage *)maskImage
{
    // Check pre-conditions.
    if (self.size.width < 1 || self.size.height < 1)
    {
        NSLog (@"*** error: invalid size: (%.2f x %.2f). Both dimensions must be >= 1: %@", self.size.width, self.size.height, self);
        return self;
    }
    if (!self.CGImage)
    {
        NSLog (@"*** error: image must be backed by a CGImage: %@", self);
        return self;
    }
    if (maskImage && !maskImage.CGImage)
    {
        NSLog (@"*** error: maskImage must be backed by a CGImage: %@", maskImage);
        maskImage = nil;
    }
    
    CGRect imageRect = { CGPointZero, self.size };
    UIImage *effectImage = self;
    
    BOOL hasBlur = blurRadius > __FLT_EPSILON__;
    BOOL hasSaturationChange = fabs(saturationDeltaFactor - 1.) > __FLT_EPSILON__;
    if (hasBlur || hasSaturationChange)
    {
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectInContext = UIGraphicsGetCurrentContext();
        CGContextScaleCTM(effectInContext, 1.0, -1.0);
        CGContextTranslateCTM(effectInContext, 0, -self.size.height);
        CGContextDrawImage(effectInContext, imageRect, self.CGImage);
        
        vImage_Buffer effectInBuffer;
        effectInBuffer.data     = CGBitmapContextGetData(effectInContext);
        effectInBuffer.width    = CGBitmapContextGetWidth(effectInContext);
        effectInBuffer.height   = CGBitmapContextGetHeight(effectInContext);
        effectInBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectInContext);
        
        UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
        CGContextRef effectOutContext = UIGraphicsGetCurrentContext();
        vImage_Buffer effectOutBuffer;
        effectOutBuffer.data     = CGBitmapContextGetData(effectOutContext);
        effectOutBuffer.width    = CGBitmapContextGetWidth(effectOutContext);
        effectOutBuffer.height   = CGBitmapContextGetHeight(effectOutContext);
        effectOutBuffer.rowBytes = CGBitmapContextGetBytesPerRow(effectOutContext);
        
        if (hasBlur)
        {
            // A description of how to compute the box kernel width from the Gaussian
            // radius (aka standard deviation) appears in the SVG spec:
            // http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
            //
            // For larger values of 's' (s >= 2.0), an approximation can be used: Three
            // successive box-blurs build a piece-wise quadratic convolution kernel, which
            // approximates the Gaussian kernel to within roughly 3%.
            //
            // let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
            //
            // ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
            //
            CGFloat inputRadius = blurRadius * [[UIScreen mainScreen] scale];
            NSUInteger radius = floor(inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5);
            if (radius % 2 != 1)
            {
                radius += 1; // force radius to be odd so that the three box-blur methodology works.
            }
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectOutBuffer, &effectInBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
            vImageBoxConvolve_ARGB8888(&effectInBuffer, &effectOutBuffer, NULL, 0, 0, (uint32_t)radius, (uint32_t)radius, 0, kvImageEdgeExtend);
        }
        
        BOOL effectImageBuffersAreSwapped = NO;
        
        if (hasSaturationChange)
        {
            CGFloat s = saturationDeltaFactor;
            CGFloat floatingPointSaturationMatrix[] = {
                0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
                0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
                0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
                0,                    0,                    0,                    1,
            };
            const int32_t divisor = 256;
            NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) / sizeof(floatingPointSaturationMatrix[0]);
            int16_t saturationMatrix[matrixSize];
            for (NSUInteger i = 0; i < matrixSize; ++i)
            {
                saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
            }
            
            if (hasBlur)
            {
                vImageMatrixMultiply_ARGB8888(&effectOutBuffer, &effectInBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
                effectImageBuffersAreSwapped = YES;
            }
            else
            {
                vImageMatrixMultiply_ARGB8888(&effectInBuffer, &effectOutBuffer, saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);
            }
        }
        
        if (!effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        if (effectImageBuffersAreSwapped)
            effectImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    // Set up output context.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, [[UIScreen mainScreen] scale]);
    CGContextRef outputContext = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(outputContext, 1.0, -1.0);
    CGContextTranslateCTM(outputContext, 0, -self.size.height);
    
    // Draw base image.
    CGContextDrawImage(outputContext, imageRect, self.CGImage);
    
    // Draw effect image.
    if (hasBlur || hasSaturationChange)
    {
        CGContextSaveGState(outputContext);
        if (maskImage)
        {
            CGContextClipToMask(outputContext, imageRect, maskImage.CGImage);
        }
        CGContextDrawImage(outputContext, imageRect, effectImage.CGImage);
        CGContextRestoreGState(outputContext);
    }
    
    // Add in color tint.
    if (tintColor)
    {
        CGContextSaveGState(outputContext);
        CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
        CGContextFillRect(outputContext, imageRect);
        CGContextRestoreGState(outputContext);
    }
    
    // Output image is ready.
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end

@implementation UIImage (Resize)

//See http://stackoverflow.com/a/2658801/397210
- (UIImage *)imageScaledToSize:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end