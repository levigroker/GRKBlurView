//
//  GRKViewController.m
//  GRKBlurViewTestApp
//
//  Created by Levi Brown on 1/8/14.
//  Copyright (c) 2014 Levi Brown. All rights reserved.
//

#import "GRKViewController.h"
#import "GRKBlurView.h"

typedef NS_ENUM(NSUInteger, GRKBlurTargetType) {
    GRKBlurTargetTypeView = 0,
    GRKBlurTargetTypeImage
};

@interface GRKViewController ()

@property (nonatomic,weak) IBOutlet UIImageView *imageView;
@property (nonatomic,weak) IBOutlet GRKBlurView *blurView;
@property (nonatomic,weak) IBOutlet UISlider *blurSlider;
@property (nonatomic,weak) IBOutlet UISlider *alphaSlider;
@property (nonatomic,weak) IBOutlet UITextField *maxTextField;
@property (nonatomic,weak) IBOutlet UILabel *currentRadiusLabel;
@property (nonatomic,weak) IBOutlet UISlider *saturationSlider;
@property (nonatomic,weak) IBOutlet UILabel *currentSaturationLabel;
@property (nonatomic,weak) IBOutlet UISegmentedControl *segmentedControl;
@property (nonatomic,weak) IBOutlet UIView *componentTestView;
@property (nonatomic,weak) IBOutlet UIButton *snapshotButton;

- (IBAction)blurSliderAction:(UISlider *)slider;
- (IBAction)saturationSliderAction:(UISlider *)slider;
- (IBAction)segmentedControlAction:(UISegmentedControl *)segmentedControl;
- (IBAction)snapshotAction;

@end

@implementation GRKViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self setBlurTarget:GRKBlurTargetTypeImage];

    self.alphaSlider.value = self.blurView.alpha;
    [self updateBlurRadiusFromPercent:self.blurSlider.value];

    self.saturationSlider.value = self.blurView.saturationDeltaFactor;
    self.currentSaturationLabel.text = [NSString stringWithFormat:@"%.2f", self.blurView.saturationDeltaFactor];
}

#pragma mark - Actions

- (IBAction)blurSliderAction:(UISlider *)slider
{
    [self updateBlurRadiusFromPercent:slider.value];
}

- (IBAction)alphaSliderAction:(UISlider *)slider
{
    self.blurView.alpha = slider.value;
}

- (IBAction)saturationSliderAction:(UISlider *)slider
{
    self.blurView.saturationDeltaFactor = slider.value;
    [self.blurView update];
    self.currentSaturationLabel.text = [NSString stringWithFormat:@"%.2f", self.blurView.saturationDeltaFactor];
}

- (IBAction)segmentedControlAction:(UISegmentedControl *)segmentedControl
{
    [self setBlurTarget:segmentedControl.selectedSegmentIndex];
}

- (IBAction)snapshotAction
{
    [self.blurView setTargetImageFromView:self.componentTestView];
}

#pragma mark - Helpers

- (void)setBlurTarget:(GRKBlurTargetType)type
{
    self.segmentedControl.selectedSegmentIndex = type;
    switch (type) {
        case GRKBlurTargetTypeView:
            [self.blurView setTargetImageFromView:self.componentTestView];
            self.imageView.alpha = 0.0f;
            self.snapshotButton.enabled = YES;
            break;
        case GRKBlurTargetTypeImage:
            self.blurView.targetImage = self.imageView.image;
            self.imageView.alpha = 1.0f;
            self.snapshotButton.enabled = NO;
            break;
        default:
            break;
    }
}

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
