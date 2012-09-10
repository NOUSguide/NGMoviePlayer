//
//  NGMoviePlayerDefaultLayout.m
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 10.09.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerDefaultLayout.h"
#import "NGScrubber.h"
#import "NGVolumeControl.h"


#define kMinWidthToDisplaySkipButtons          420.f
#define kControlWidth                          (UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 44.f : 50.f)


@interface NGMoviePlayerDefaultLayout ()

@property (nonatomic, readonly) UIImage *bottomControlFullscreenImage;

@end


@implementation NGMoviePlayerDefaultLayout

@synthesize bottomControlFullscreenImage = _bottomControlFullscreenImage;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)init {
    if ((self = [super init])) {
        _scrubberFillColor = [UIColor grayColor];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerLayout
////////////////////////////////////////////////////////////////////////

- (void)customizeTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // do nothing special here
}

- (void)customizeBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // update styling of bottom controls view
    UIImageView *bottomControlsImageView = (UIImageView *)self.bottomControlsView;

    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        bottomControlsImageView.backgroundColor = [UIColor clearColor];
        bottomControlsImageView.image = self.bottomControlFullscreenImage;
    } else if (controlStyle == NGMoviePlayerControlStyleInline) {
        bottomControlsImageView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
        bottomControlsImageView.image = nil;
    }
}

- (void)customizeControlsWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    [self setupScrubber:self.scrubberControl controlStyle:controlStyle];
}

- (void)layoutTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    self.topControlsView.frame = CGRectMake(0.f,
                                            (self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f),
                                            self.width,
                                            [self topControlsViewHeightForControlStyle:controlStyle]);

    // center custom controls in top container
    self.topControlsContainerView.frame = CGRectMake(MAX((self.topControlsView.frame.size.width - self.topControlsContainerView.frame.size.width)/2.f, 0.f),
                                                     0.f,
                                                     self.topControlsContainerView.frame.size.width,
                                                     [self topControlsViewHeightForControlStyle:controlStyle]);
}

- (void)layoutBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    CGFloat controlsViewHeight = [self bottomControlsViewHeightForControlStyle:controlStyle];
    CGFloat offset = (self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f);

    self.bottomControlsView.frame = CGRectMake(offset,
                                               self.height-controlsViewHeight,
                                               self.width - 2.f*offset,
                                               controlsViewHeight-offset);
}

- (void)layoutControlsWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleInline) {
        [self layoutSubviewsForControlStyleInline];
    } else {
        [self layoutSubviewsForControlStyleFullscreen];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerDefaultLayout
////////////////////////////////////////////////////////////////////////

- (void)setScrubberFillColor:(UIColor *)scrubberFillColor {
    self.scrubberControl.fillColor = scrubberFillColor;
    self.volumeControl.minimumTrackColor = scrubberFillColor;

    // customize scrubber with new color
    [self updateControlStyle:self.controlStyle];
}

- (void)setScrubberHidden:(BOOL)scrubberHidden {
    if (scrubberHidden != _scrubberHidden) {
        _scrubberHidden = scrubberHidden;

        [self invalidateLayout];
    }
}

- (void)setSkipButtonsHidden:(BOOL)skipButtonsHidden {
    if (skipButtonsHidden != _skipButtonsHidden) {
        _skipButtonsHidden = skipButtonsHidden;

        [self invalidateLayout];
    }
}

- (void)addTopControlsViewButton:(UIButton *)button {
    CGFloat maxX = 0.f;
    CGFloat height = [self topControlsViewHeightForControlStyle:self.controlStyle];

    for (UIView *subview in self.topControlsContainerView.subviews) {
        maxX = MAX(subview.frame.origin.x + subview.frame.size.width, maxX);
    }

    if (maxX > 0.f) {
        maxX += self.topControlsViewButtonPadding;
    }

    button.frame = CGRectMake(maxX, 0.f, button.frame.size.width, height);
    [self.topControlsContainerView addSubview:button];
    self.topControlsContainerView.frame = CGRectMake(0.f, 0.f, maxX + button.frame.size.width, height);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setupScrubber:(NGScrubber *)scrubber controlStyle:(NGMoviePlayerControlStyle)controlStyle {
    CGFloat height = 20.f;
    CGFloat radius = 8.f;

    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberKnobFullscreen"]
                       forState:UIControlStateNormal];
    } else {
        height = 10.f;

        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberKnob"]
                       forState:UIControlStateNormal];
    }

    //Build a roundedRect of appropriate size at origin 0,0
    UIBezierPath* roundedRect = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, height, height) cornerRadius:radius];
    //Color for Stroke
    CGColorRef strokeColor = [[UIColor blackColor] CGColor];

    // create minimum track image
    UIGraphicsBeginImageContext(CGSizeMake(height, height));
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    //Set the fill color
    CGContextSetFillColorWithColor(currentContext, self.scrubberControl.fillColor.CGColor);
    //Fill the color
    [roundedRect fill];
    //Draw stroke
    CGContextSetStrokeColorWithColor(currentContext, strokeColor);
    [roundedRect stroke];
    //Snap the picture and close the context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //generate stretchable Image
    if ([image respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius)];
    } else {
        image = [image stretchableImageWithLeftCapWidth:radius topCapHeight:radius];
    }
    [scrubber setMinimumTrackImage:image forState:UIControlStateNormal];

    // create maximum track image
    UIGraphicsBeginImageContext(CGSizeMake(height, height));
    currentContext = UIGraphicsGetCurrentContext();
    //Set the fill color
    CGContextSetFillColorWithColor(currentContext, [UIColor colorWithWhite:1.f alpha:.2f].CGColor);
    //Fill the color
    [roundedRect fill];
    //Draw stroke
    CGContextSetStrokeColorWithColor(currentContext, strokeColor);
    [roundedRect stroke];
    //Snap the picture and close the context
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    //generate stretchable Image
    if ([image respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(radius, radius, radius, radius)];
    } else {
        image = [image stretchableImageWithLeftCapWidth:radius topCapHeight:radius];
    }
    [scrubber setMaximumTrackImage:image forState:UIControlStateNormal];

    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        scrubber.playableValueRoundedRectRadius = radius;
    } else {
        scrubber.playableValueRoundedRectRadius = 2.f;
    }

    // force re-draw of playable value of scrubber
    scrubber.playableValue = scrubber.playableValue;
}

- (CGFloat)topControlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    return [self bottomControlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline];
}

- (CGFloat)bottomControlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        return 105.f;
    } else {
        return 40.f;
    }
}

- (UIImage *)bottomControlFullscreenImage {
    if (_bottomControlFullscreenImage == nil) {
        _bottomControlFullscreenImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/fullscreen-hud"];

        // make it a resizable image
        if ([_bottomControlFullscreenImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
            _bottomControlFullscreenImage = [_bottomControlFullscreenImage resizableImageWithCapInsets:UIEdgeInsetsMake(48.f, 15.f, 46.f, 15.f)];
        } else {
            _bottomControlFullscreenImage = [_bottomControlFullscreenImage stretchableImageWithLeftCapWidth:15 topCapHeight:47];
        }
    }

    return _bottomControlFullscreenImage;
}

- (void)layoutSubviewsForControlStyleInline {
    CGFloat width = self.width;
    CGFloat controlsViewHeight = [self bottomControlsViewHeightForControlStyle:self.controlStyle];
    CGFloat leftEdge = 0.f;
    CGFloat rightEdge = width;   // the right edge of the last positioned button in the bottom controls view (starting from right)

    // skip buttons always hidden in inline mode
    self.rewindControl.hidden = YES;
    self.forwardControl.hidden = YES;

    // play button always on the left
    self.playPauseControl.frame = CGRectMake(0.f, 0.f, kControlWidth, controlsViewHeight);
    leftEdge = self.playPauseControl.frame.origin.x + self.playPauseControl.frame.size.width;

    // volume control and zoom button are always on the right
    self.zoomControl.frame = CGRectMake(width-kControlWidth, 0.f, kControlWidth, controlsViewHeight);
    [self.zoomControl setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomIn"] forState:UIControlStateNormal];

    self.volumeControl.frame = CGRectMake(rightEdge-kControlWidth, self.bottomControlsView.frame.origin.y, kControlWidth, controlsViewHeight);
    rightEdge = self.volumeControl.frame.origin.x;

    // we always position the airplay button, but only update the left edge when the button is visible
    // this is a workaround for a layout bug I can't remember
    self.airPlayControlContainer.frame = CGRectMake(rightEdge-kControlWidth, 0.f, kControlWidth, controlsViewHeight);
    if (self.airPlayControlVisible) {
        rightEdge = self.airPlayControlContainer.frame.origin.x;
    }

    self.currentTimeLabel.frame = CGRectMake(leftEdge, 0.f, 55.f, controlsViewHeight);
    self.currentTimeLabel.textAlignment = UITextAlignmentCenter;
    leftEdge = self.currentTimeLabel.frame.origin.x + self.currentTimeLabel.frame.size.width;

    self.remainingTimeLabel.frame = CGRectMake(rightEdge-60.f, 0.f, 60.f, controlsViewHeight);
    self.remainingTimeLabel.textAlignment = UITextAlignmentCenter;
    rightEdge = self.remainingTimeLabel.frame.origin.x;

    // scrubber uses remaining width
    self.scrubberControl.frame = CGRectMake(leftEdge, 0.f, rightEdge - leftEdge, controlsViewHeight);
}

- (void)layoutSubviewsForControlStyleFullscreen {
    BOOL displaySkipButtons = NO; // TODO !self.skipButtonsHidden && (self.bottomControlsView.frame.size.width > kMinWidthToDisplaySkipButtons);
    CGFloat width = self.bottomControlsView.frame.size.width;
    CGFloat controlsViewHeight = 44.f;
    CGFloat outerPadding = UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 5.f : 12.f;
    CGFloat buttonTopPadding = 20.f;
    CGFloat leftEdge = 0.f;
    CGFloat rightEdge = width;   // the right edge of the last positioned button in the bottom controls view (starting from right)

    // play button always on the left
    self.playPauseControl.frame = CGRectMake(outerPadding, buttonTopPadding, kControlWidth, controlsViewHeight);
    leftEdge = self.playPauseControl.frame.origin.x + self.playPauseControl.frame.size.width;

    // zoom button can be left or right
    UIImage *zoomButtonImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/zoomOut"];
    CGFloat zoomButtonWidth = MAX(zoomButtonImage.size.width, kControlWidth);
    [self.zoomControl setImage:zoomButtonImage forState:UIControlStateNormal];
    //TODO if (self.zoomOutButtonPosition == NGMoviePlayerControlViewZoomOutButtonPositionLeft) {
    //    self.zoomControl.frame = CGRectMake(0.f, 0.f, zoomButtonWidth, self.topControlsView.bounds.size.height);
    //} else {
        self.zoomControl.frame = CGRectMake(self.width - zoomButtonWidth, 0.f, zoomButtonWidth, self.topControlsView.bounds.size.height);
    //}

    // volume control is always right
    self.volumeControl.frame = CGRectMake(rightEdge + self.bottomControlsView.frame.origin.x - kControlWidth - outerPadding, self.bottomControlsView.frame.origin.y + buttonTopPadding, kControlWidth, controlsViewHeight);
    rightEdge = self.volumeControl.frame.origin.x - self.bottomControlsView.frame.origin.x;

    // we always position the airplay button, but only update the left edge when the button is visible
    // this is a workaround for a layout bug I can't remember
    self.airPlayControlContainer.frame = CGRectMake(rightEdge-kControlWidth, buttonTopPadding + 2.f, kControlWidth, controlsViewHeight);
    if (self.airPlayControlVisible) {
        rightEdge = self.airPlayControlContainer.frame.origin.x;
    }

    // skip buttons can be shown or hidden
    self.rewindControl.hidden = !displaySkipButtons;
    self.forwardControl.hidden = !displaySkipButtons;

    if (displaySkipButtons) {
        self.rewindControl.frame = CGRectMake(leftEdge, buttonTopPadding, kControlWidth, controlsViewHeight);
        self.forwardControl.frame = CGRectMake(rightEdge - kControlWidth, buttonTopPadding, kControlWidth, controlsViewHeight);

        leftEdge = self.rewindControl.frame.origin.x + self.rewindControl.frame.size.width;
        rightEdge = self.forwardControl.frame.origin.x;
    }

    self.scrubberControl.frame = CGRectMake(leftEdge, buttonTopPadding + 12.f, rightEdge - leftEdge, 20.f);
    //TODO self.scrubberControl.hidden = self.scrubberHidden;

    self.currentTimeLabel.frame = CGRectMake(leftEdge + 10.f, self.scrubberControl.frame.origin.y, 60.f, 20.f);
    self.currentTimeLabel.textAlignment = UITextAlignmentLeft;

    self.remainingTimeLabel.frame = CGRectMake(rightEdge - 70.f, self.scrubberControl.frame.origin.y, 60.f, 20.f);
    self.remainingTimeLabel.textAlignment = UITextAlignmentRight;
}

@end
