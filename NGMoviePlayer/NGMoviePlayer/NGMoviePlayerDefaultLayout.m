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
#import "NGMoviePlayer.h"
#import "NGMoviePlayerView.h"

#define kMinWidthToDisplaySkipButtons          420.f
#define kControlWidth                          (UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 44.f : 50.f)


@interface NGMoviePlayerDefaultLayout () {
    NSMutableArray *_topControlsButtons;
}

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
        _minWidthToDisplaySkipButtons = kMinWidthToDisplaySkipButtons;

        _topControlsButtons = [NSMutableArray array];
        _topControlsViewAlignment = NGMoviePlayerControlViewTopControlsViewAlignmentCenter;
        _zoomOutButtonPosition = NGMoviePlayerControlViewZoomOutButtonPositionRight;
        _topControlsViewButtonPadding = 35.f;
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
    CGFloat topControlsViewTop = 0.f;
    
    CGSize windowSize = self.moviePlayer.view.window.bounds.size;
    CGSize playerViewSize = self.moviePlayer.view.frame.size;
    CGSize playerViewInvertedSize = CGSizeMake(playerViewSize.height, playerViewSize.width);
    if (CGSizeEqualToSize(windowSize, playerViewSize) || CGSizeEqualToSize(windowSize, playerViewInvertedSize)) {
        topControlsViewTop = 20.f;
    }

    self.topControlsView.frame = CGRectMake(0.f,
                                            topControlsViewTop,
                                            self.width,
                                            [self topControlsViewHeightForControlStyle:controlStyle]);

    if (self.topControlsViewAlignment == NGMoviePlayerControlViewTopControlsViewAlignmentCenter) {
        // center custom controls in top container
        self.topControlsContainerView.frame = CGRectMake(MAX((self.topControlsView.frame.size.width - self.topControlsContainerView.frame.size.width)/2.f, 0.f),
                                                         topControlsViewTop,
                                                         self.topControlsContainerView.frame.size.width,
                                                         [self topControlsViewHeightForControlStyle:controlStyle]);
    } else {
        self.topControlsContainerView.frame = CGRectMake(2.f,
                                                         topControlsViewTop,
                                                         self.topControlsContainerView.frame.size.width,
                                                         [self topControlsViewHeightForControlStyle:controlStyle]);
    }
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

    [_topControlsButtons addObject:button];
}

- (void)setTopControlsViewButtonPadding:(CGFloat)topControlsViewButtonPadding {
    if (topControlsViewButtonPadding != _topControlsViewButtonPadding) {
        _topControlsViewButtonPadding = topControlsViewButtonPadding;

        [self layoutTopControlsViewButtons];
    }
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
    BOOL displaySkipButtons = !self.skipButtonsHidden && !self.playingLivestream && (self.bottomControlsView.frame.size.width > self.minWidthToDisplaySkipButtons);
    CGFloat width = self.bottomControlsView.bounds.size.width;
    CGFloat outerPadding = UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 5.f : 10.f;
    CGFloat controlWidth = UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 44.f : 50.f;
    CGFloat offset = UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 54.f : 66.f;
    CGFloat controlHeight = 44.f;
    CGFloat topY = 2.f;

    // zoom button can be left or right
    UIImage *zoomButtonImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/zoomOut"];
    CGFloat zoomButtonWidth = MAX(zoomButtonImage.size.width, 50.f);
    [self.zoomControl setImage:zoomButtonImage forState:UIControlStateNormal];
    if (self.zoomOutButtonPosition == NGMoviePlayerControlViewZoomOutButtonPositionLeft) {
        self.zoomControl.frame = CGRectMake(0.f, 0.f, zoomButtonWidth, self.topControlsView.bounds.size.height);
    } else {
        self.zoomControl.frame = CGRectMake(self.width - zoomButtonWidth, 0.f, zoomButtonWidth, self.topControlsView.bounds.size.height);
    }

    // play/skip segment centered in first row
    self.playPauseControl.center = CGPointMake(width/2.f, topY + controlHeight/2.f);
    self.rewindControl.frame = CGRectOffset(self.playPauseControl.frame, -offset, 0.f);
    self.forwardControl.frame = CGRectOffset(self.playPauseControl.frame, offset, 0.f);
    self.rewindControl.hidden = !displaySkipButtons;
    self.forwardControl.hidden = !displaySkipButtons;

    // volume right-aligned in first row
    self.volumeControl.frame = CGRectMake(width + self.bottomControlsView.frame.origin.x - controlWidth - outerPadding, self.bottomControlsView.frame.origin.y + topY, controlWidth, controlHeight);
    // airplay left-aligned
    self.airPlayControlContainer.frame = CGRectMake(outerPadding, topY+2.f, controlWidth, controlHeight);

    // next row of controls
    topY += controlHeight + 5.f;

    self.currentTimeLabel.frame = CGRectMake(outerPadding, topY, 55.f, 20.f);
    self.currentTimeLabel.textAlignment = UITextAlignmentCenter;
    self.remainingTimeLabel.frame = CGRectMake(width - 55.f - outerPadding, topY, 55.f, 20.f);
    self.remainingTimeLabel.textAlignment = UITextAlignmentCenter;
    self.scrubberControl.frame = CGRectMake(CGRectGetMaxX(self.currentTimeLabel.frame) + 8.f, topY, self.remainingTimeLabel.frame.origin.x - CGRectGetMaxX(self.currentTimeLabel.frame) - 16.f, 20.f);
}

- (void)layoutTopControlsViewButtons {
    CGFloat maxX = 0.f;
    CGFloat height = [self topControlsViewHeightForControlStyle:self.controlStyle];

    for (UIView *button in self.topControlsButtons) {
        button.frame = CGRectMake(maxX, 0.f, button.frame.size.width, height);
        maxX = button.frame.origin.x + button.frame.size.width + self.topControlsViewButtonPadding;
    }
    
    maxX -= self.topControlsViewButtonPadding;
    self.topControlsContainerView.frame = CGRectMake(0.f, 0.f, maxX, height);
}

@end
