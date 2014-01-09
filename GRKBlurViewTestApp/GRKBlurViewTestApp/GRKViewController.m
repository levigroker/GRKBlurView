//
//  GRKViewController.m
//  GRKBlurViewTestApp
//
//  Created by Levi Brown on 1/8/14.
//  Copyright (c) 2014 Levi Brown. All rights reserved.
//

#import "GRKViewController.h"
#import "GRKBlurView.h"

@interface GRKViewController ()

@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (nonatomic,weak) IBOutlet GRKBlurView *blurView;
@property (nonatomic,weak) IBOutlet UISlider *blurSlider;
@property (nonatomic,weak) IBOutlet UITextField *maxTextField;
@property (nonatomic,weak) IBOutlet UILabel *currentRadiusLabel;
@property (nonatomic,weak) IBOutlet UISlider *saturationSlider;
@property (nonatomic,weak) IBOutlet UILabel *currentSaturationLabel;

- (IBAction)blurSliderAction:(UISlider *)slider;
- (IBAction)saturationSliderAction:(UISlider *)slider;

@end

@implementation GRKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.blurView.targetImage = self.imageView.image;
    [self updateBlurRadiusFromPercent:self.blurSlider.value];

    self.saturationSlider.value = self.blurView.saturationDeltaFactor;
    self.currentSaturationLabel.text = [NSString stringWithFormat:@"%.2f", self.blurView.saturationDeltaFactor];
}

#pragma mark - Actions

- (IBAction)blurSliderAction:(UISlider *)slider
{
    [self updateBlurRadiusFromPercent:slider.value];
}

- (IBAction)saturationSliderAction:(UISlider *)slider
{
    self.blurView.saturationDeltaFactor = slider.value;
    [self.blurView update];
    self.currentSaturationLabel.text = [NSString stringWithFormat:@"%.2f", self.blurView.saturationDeltaFactor];
}

#pragma mark - Helpers

- (void)updateBlurRadiusFromPercent:(CGFloat)percent
{
    CGFloat maxBlurRadius = [self maxBlurRadius];
    [self.blurView updateBlurRadiusFromPercent:percent ofMax:(CGFloat)maxBlurRadius];
    self.currentRadiusLabel.text = [NSString stringWithFormat:@"%.2f", self.blurView.blurRadius];
}

- (CGFloat)maxBlurRadius
{
    CGFloat value = [self.maxTextField.text floatValue];
    return value;
}

@end
