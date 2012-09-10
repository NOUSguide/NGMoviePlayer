//
//  NGMoviePlayerControlView.m
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerControlActionDelegate.h"
#import "NGScrubber.h"
#import "NGVolumeControl.h"
#import "NGMoviePlayerFunctions.h"


#define kControlAlphaValue                     0.6f
#define kMinWidthToDisplaySkipButtons          420.f
#define kControlWidth                          (UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 44.f : 50.f)


NSString * const NGMoviePlayerControlViewTopControlsViewKey = @"NGMoviePlayerControlViewTopControlsViewKey";
NSString * const NGMoviePlayerControlViewBottomControlsViewKey = @"NGMoviePlayerControlViewBottomControlsViewKey";
NSString * const NGMoviePlayerControlViewPlayPauseButtonKey = @"NGMoviePlayerControlViewPlayPauseButtonKey";
NSString * const NGMoviePlayerControlViewScrubberKey = @"NGMoviePlayerControlViewScrubberKey";
NSString * const NGMoviePlayerControlViewRewindButtonKey = @"NGMoviePlayerControlViewRewindButtonKey";
NSString * const NGMoviePlayerControlViewForwardButtonKey = @"NGMoviePlayerControlViewForwardButtonKey";
NSString * const NGMoviePlayerControlViewAirPlayButtonKey = @"NGMoviePlayerControlViewAirPlayButtonKey";
NSString * const NGMoviePlayerControlViewVolumeControlKey = @"NGMoviePlayerControlViewVolumeControlKey";
NSString * const NGMoviePlayerControlViewZoomButtonKey = @"NGMoviePlayerControlViewZoomButtonKey";
NSString * const NGMoviePlayerControlViewCurrentTimeLabelKey = @"NGMoviePlayerControlViewCurrentTimeLabelKey";
NSString * const NGMoviePlayerControlViewRemainingTimeLabelKey = @"NGMoviePlayerControlViewRemainingTimeLabelKey";
NSString * const NGMoviePlayerControlViewTopButtonContainerKey = @"NGMoviePlayerControlViewTopButtonContainerKey";


@interface NGMoviePlayerControlView () {
    BOOL _statusBarHidden;
    NSMutableArray *_topControlsViewButtons;
}

@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) UIControl *airPlayButtonContainer;
@property (nonatomic, strong) MPVolumeView *airPlayButton;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;
@property (nonatomic, strong) UIView *topButtonContainer;
@property (nonatomic, strong) UIImage *bottomControlFullscreenImage;
@property (nonatomic, readonly, getter = isPlayingLivestream) BOOL playingLivestream;
@property (nonatomic, strong) NSDictionary *controls;

@end


@implementation NGMoviePlayerControlView

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _scrubberFillColor = [UIColor grayColor];

        _topControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _topControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:kControlAlphaValue];
        [self addSubview:_topControlsView];

        _topControlsViewButtons = [NSMutableArray new];

        _topButtonContainer = [[UIView alloc] initWithFrame:CGRectZero];
        _topButtonContainer.backgroundColor = [UIColor clearColor];
        _topControlsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [_topControlsView addSubview:_topButtonContainer];

        _bottomControlFullscreenImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/fullscreen-hud"];
        if ([_bottomControlFullscreenImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
            _bottomControlFullscreenImage = [_bottomControlFullscreenImage resizableImageWithCapInsets:UIEdgeInsetsMake(48.f, 15.f, 46.f, 15.f)];
        } else {
            _bottomControlFullscreenImage = [_bottomControlFullscreenImage stretchableImageWithLeftCapWidth:15 topCapHeight:47];
        }
        _bottomControlsView = [[UIImageView alloc] initWithImage:_bottomControlFullscreenImage];
        _bottomControlsView.userInteractionEnabled = YES;
        _bottomControlsView.frame = CGRectZero;
        _bottomControlsView.backgroundColor = [UIColor clearColor];
        [self addSubview:_bottomControlsView];

        _volumeControl = [[NGVolumeControl alloc] initWithFrame:CGRectZero];
        _volumeControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_volumeControl addTarget:self action:@selector(handleVolumeChanged:) forControlEvents:UIControlEventValueChanged];
        if (UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone) {
            _volumeControl.sliderHeight = 130.f;
        }
        // volume control needs to get added to self instead of bottomControlView because otherwise the expanded slider
        // doesn't receive any touch events
        [self addSubview:_volumeControl];


        // We use the MPVolumeView just for displaying the AirPlay icon
        if ([AVPlayer instancesRespondToSelector:@selector(allowsAirPlayVideo)]) {
            _airPlayButton = [[MPVolumeView alloc] initWithFrame:(CGRect) { .size = CGSizeMake(38.f, 24.f) }];
            _airPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            _airPlayButton.contentMode = UIViewContentModeCenter;
            _airPlayButton.showsRouteButton = YES;
            _airPlayButton.showsVolumeSlider = NO;

            _airPlayButtonContainer = [[UIControl alloc] initWithFrame:CGRectMake(0.f, 0.f, kControlWidth, [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline])];
            _airPlayButton.center = CGPointMake(_airPlayButtonContainer.frame.size.width/2.f, _airPlayButtonContainer.frame.size.height/2.f + 2.f);
            [_airPlayButtonContainer addTarget:self action:@selector(handleAirPlayButtonPress:) forControlEvents:UIControlEventTouchUpInside];
            [_airPlayButtonContainer addSubview:_airPlayButton];
            [_bottomControlsView addSubview:_airPlayButtonContainer];
        }

        _rewindButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rewindButton.frame = CGRectMake(60.f, 10.f, 40.f, 40.f);
        _rewindButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _rewindButton.showsTouchWhenHighlighted = YES;
        [_rewindButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/rewind"] forState:UIControlStateNormal];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_rewindButton];

        _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _forwardButton.frame = _rewindButton.frame;
        _forwardButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _forwardButton.showsTouchWhenHighlighted = YES;
        [_forwardButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/forward"] forState:UIControlStateNormal];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_forwardButton];

        _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playPauseButton.contentMode = UIViewContentModeCenter;
        _playPauseButton.showsTouchWhenHighlighted = YES;
        _playPauseButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_playPauseButton addTarget:self action:@selector(handlePlayPauseButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomControlsView addSubview:_playPauseButton];

        _scrubber = [[NGScrubber alloc] initWithFrame:CGRectZero];
        _scrubber.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_scrubber addTarget:self action:@selector(handleBeginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [_scrubber addTarget:self action:@selector(handleScrubbingValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_scrubber addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [_scrubber addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_scrubber];

        _zoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _zoomButton.showsTouchWhenHighlighted = YES;
        _zoomButton.contentMode = UIViewContentModeCenter;
        [_zoomButton addTarget:self action:@selector(handleZoomButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_topControlsView addSubview:_zoomButton];

        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _currentTimeLabel.backgroundColor = [UIColor clearColor];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.shadowColor = [UIColor blackColor];
        _currentTimeLabel.shadowOffset = CGSizeMake(0.f, 1.f);
        _currentTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _currentTimeLabel.textAlignment = UITextAlignmentRight;
        _currentTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [_bottomControlsView addSubview:_currentTimeLabel];

        _remainingTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _remainingTimeLabel.backgroundColor = [UIColor clearColor];
        _remainingTimeLabel.textColor = [UIColor whiteColor];
        _remainingTimeLabel.shadowColor = [UIColor blackColor];
        _remainingTimeLabel.shadowOffset = CGSizeMake(0.f, 1.f);
        _remainingTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _remainingTimeLabel.textAlignment = UITextAlignmentLeft;
        _remainingTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_bottomControlsView addSubview:_remainingTimeLabel];

        [self setupScrubber:_scrubber controlStyle:_controlStyle];

        _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;

        _controls = [NSDictionary dictionaryWithObjectsAndKeys:
                     _topControlsView, NGMoviePlayerControlViewTopControlsViewKey,
                     _bottomControlsView, NGMoviePlayerControlViewBottomControlsViewKey,
                     _playPauseButton, NGMoviePlayerControlViewPlayPauseButtonKey,
                     _scrubber, NGMoviePlayerControlViewScrubberKey,
                     _rewindButton, NGMoviePlayerControlViewRewindButtonKey,
                     _forwardButton, NGMoviePlayerControlViewForwardButtonKey,
                     _airPlayButtonContainer, NGMoviePlayerControlViewAirPlayButtonKey,
                     _volumeControl, NGMoviePlayerControlViewVolumeControlKey,
                     _zoomButton, NGMoviePlayerControlViewZoomButtonKey,
                     _currentTimeLabel, NGMoviePlayerControlViewCurrentTimeLabelKey,
                     _remainingTimeLabel, NGMoviePlayerControlViewRemainingTimeLabelKey,
                     _topButtonContainer, NGMoviePlayerControlViewTopButtonContainerKey,
                     nil];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)setAlpha:(CGFloat)alpha {
    // otherwise the airPlayButton isn't positioned correctly on first show-up
    if (alpha > 0.f) {
        [self setNeedsLayout];
    }

    [super setAlpha:alpha];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat controlsViewHeight = [self controlsViewHeightForControlStyle:self.controlStyle];
    CGFloat offset = self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f;

    _topControlsView.frame = CGRectMake(0.f, (self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f), self.bounds.size.width, [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline]);
    _bottomControlsView.frame = CGRectMake(offset, self.bounds.size.height-controlsViewHeight, self.bounds.size.width - 2.f*offset, controlsViewHeight-offset);

    // center custom controls in top container
    self.topButtonContainer.frame = CGRectMake(MAX((self.topControlsView.frame.size.width - self.topButtonContainer.frame.size.width)/2.f, 0.f),
                                               0.f,
                                               self.topButtonContainer.frame.size.width,
                                               [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline]);

    // update styling of bottom controls view
    UIImageView *bottomControlsImageView = (UIImageView *)self.bottomControlsView;

    if (self.controlStyle == NGMoviePlayerControlStyleFullscreen) {
        bottomControlsImageView.backgroundColor = [UIColor clearColor];
        bottomControlsImageView.image = self.bottomControlFullscreenImage;
    } else if (self.controlStyle == NGMoviePlayerControlStyleInline) {
        bottomControlsImageView.backgroundColor = [UIColor colorWithWhite:0.f alpha:kControlAlphaValue];
        bottomControlsImageView.image = nil;
    }

    if (self.layoutSubviewsBlock) {
        self.layoutSubviewsBlock(self.controlStyle, self.controls);
    } else {
        [self layoutSubviewsForControlStyle:self.controlStyle];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerControlView
////////////////////////////////////////////////////////////////////////

- (void)layoutSubviewsForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        [self layoutSubviewsForControlStyleFullscreen];
    } else if (controlStyle == NGMoviePlayerControlStyleInline) {
        [self layoutSubviewsForControlStyleInline];
    }
}

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle != _controlStyle) {
        _controlStyle = controlStyle;

        [self setupScrubber:self.scrubber controlStyle:controlStyle];
        [self setNeedsLayout];
    }
}

- (void)setScrubberFillColor:(UIColor *)scrubberFillColor {
    if (scrubberFillColor != _scrubberFillColor) {
        _scrubberFillColor = scrubberFillColor;

        self.volumeControl.minimumTrackColor = scrubberFillColor;
        [self setupScrubber:self.scrubber controlStyle:self.controlStyle];
    }
}

- (void)setScrubberHidden:(BOOL)scrubberHidden {
    if (scrubberHidden != _scrubberHidden) {
        _scrubberHidden = scrubberHidden;

        [self setNeedsLayout];
    }
}

- (void)setSkipButtonsHidden:(BOOL)skipButtonsHidden {
    if (skipButtonsHidden != _skipButtonsHidden) {
        _skipButtonsHidden = skipButtonsHidden;

        [self setNeedsLayout];
    }
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    self.scrubber.playableValue = playableDuration;
}

- (NSTimeInterval)playableDuration {
    return self.scrubber.playableValue;
}

- (void)updateScrubberWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    self.currentTimeLabel.text = NGMoviePlayerGetTimeFormatted(currentTime);
    self.remainingTimeLabel.text = NGMoviePlayerGetRemainingTimeFormatted(currentTime, duration);

    [self.scrubber setMinimumValue:0.];
    [self.scrubber setMaximumValue:duration];
    [self.scrubber setValue:currentTime];
}

- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying {
    UIImage *image = isPlaying ? [UIImage imageNamed:@"NGMoviePlayer.bundle/pause"] : [UIImage imageNamed:@"NGMoviePlayer.bundle/play"];

    [self.playPauseButton setImage:image forState:UIControlStateNormal];
}

- (void)addTopControlsViewButton:(UIButton *)button {
    CGFloat maxX = 0.f;
    CGFloat height = [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline];

    for (UIView *subview in self.topButtonContainer.subviews) {
        maxX = MAX(subview.frame.origin.x + subview.frame.size.width, maxX);
    }

    if (maxX > 0.f) {
        maxX += self.topControlsViewButtonPadding;
    }

    button.frame = CGRectMake(maxX, 0.f, button.frame.size.width, height);
    [self.topButtonContainer addSubview:button];
    self.topButtonContainer.frame = CGRectMake(0.f, 0.f, maxX + button.frame.size.width, height);

    [_topControlsViewButtons addObject:button];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (CGFloat)controlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        return 105.f;
    } else {
        return 40.f;
    }
}

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
    CGContextSetFillColorWithColor(currentContext, self.scrubberFillColor.CGColor);
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

- (BOOL)isAirPlayButtonVisible {
    if (self.airPlayButton == nil) {
        return NO;
    }

    for (UIView *subview in self.airPlayButton.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.alpha == 0.f || subview.hidden) {
                return NO;
            }
        }
    }

    return YES;
}

- (void)handlePlayPauseButtonPress:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionTogglePlayPause];
}

- (void)handleRewindButtonTouchDown:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionBeginSkippingBackwards];
}

- (void)handleRewindButtonTouchUp:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionEndSkipping];
}

- (void)handleForwardButtonTouchDown:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionBeginSkippingForwards];
}

- (void)handleForwardButtonTouchUp:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionEndSkipping];
}

- (void)handleZoomButtonPress:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionToggleZoomState];
}

- (void)handleBeginScrubbing:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionBeginScrubbing];
}

- (void)handleScrubbingValueChanged:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionScrubbingValueChanged];
}

- (void)handleEndScrubbing:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionEndScrubbing];
}

- (void)handleVolumeChanged:(id)sender {
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionVolumeChanged];
}

- (void)handleAirPlayButtonPress:(id)sender {
    // forward touch event to airPlay-button
    for (UIView *subview in self.airPlayButton.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;

            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }
}

- (void)layoutSubviewsForControlStyleInline {
    CGFloat width = self.bounds.size.width;
    CGFloat controlsViewHeight = [self controlsViewHeightForControlStyle:self.controlStyle];
    CGFloat leftEdge = 0.f;
    CGFloat rightEdge = width;   // the right edge of the last positioned button in the bottom controls view (starting from right)

    // skip buttons always hidden in inline mode
    self.rewindButton.hidden = YES;
    self.forwardButton.hidden = YES;

    // play button always on the left
    self.playPauseButton.frame = CGRectMake(0.f, 0.f, kControlWidth, controlsViewHeight);
    leftEdge = self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width;

    // volume control and zoom button are always on the right
    self.zoomButton.frame = CGRectMake(width-kControlWidth, 0.f, kControlWidth, controlsViewHeight);
    [self.zoomButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomIn"] forState:UIControlStateNormal];

    self.volumeControl.frame = CGRectMake(width-kControlWidth, self.bottomControlsView.frame.origin.y, kControlWidth, controlsViewHeight);
    rightEdge = self.volumeControl.frame.origin.x;

    // we always position the airplay button, but only update the left edge when the button is visible
    // this is a workaround for a layout bug I can't remember
    self.airPlayButtonContainer.frame = CGRectMake(rightEdge-kControlWidth, 0.f, kControlWidth, controlsViewHeight);
    if (self.isAirPlayButtonVisible) {
        rightEdge = self.airPlayButtonContainer.frame.origin.x;
    }

    self.currentTimeLabel.frame = CGRectMake(leftEdge, 0.f, 55.f, controlsViewHeight);
    self.currentTimeLabel.textAlignment = UITextAlignmentCenter;
    leftEdge = self.currentTimeLabel.frame.origin.x + self.currentTimeLabel.frame.size.width;

    self.remainingTimeLabel.frame = CGRectMake(rightEdge-60.f, 0.f, 60.f, controlsViewHeight);
    self.remainingTimeLabel.textAlignment = UITextAlignmentCenter;
    rightEdge = self.remainingTimeLabel.frame.origin.x;

    // scrubber uses remaining width
    self.scrubber.frame = CGRectMake(leftEdge, 0.f, rightEdge - leftEdge, controlsViewHeight);
}

- (void)layoutSubviewsForControlStyleFullscreen {
    BOOL displaySkipButtons = !self.skipButtonsHidden && (_bottomControlsView.frame.size.width > kMinWidthToDisplaySkipButtons);
    CGFloat width = self.bottomControlsView.frame.size.width;
    CGFloat controlsViewHeight = 44.f;
    CGFloat outerPadding = UI_USER_INTERFACE_IDIOM()  == UIUserInterfaceIdiomPhone ? 5.f : 12.f;
    CGFloat buttonTopPadding = 20.f;
    CGFloat leftEdge = 0.f;
    CGFloat rightEdge = width;   // the right edge of the last positioned button in the bottom controls view (starting from right)

    // play button always on the left
    self.playPauseButton.frame = CGRectMake(outerPadding, buttonTopPadding, kControlWidth, controlsViewHeight);
    leftEdge = self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width;

    // zoom button can be left or right
    UIImage *zoomButtonImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/zoomOut"];
    CGFloat zoomButtonWidth = MAX(zoomButtonImage.size.width, kControlWidth);
    [self.zoomButton setImage:zoomButtonImage forState:UIControlStateNormal];
    if (self.zoomOutButtonPosition == NGMoviePlayerControlViewZoomOutButtonPositionLeft) {
        self.zoomButton.frame = CGRectMake(0.f, 0.f, zoomButtonWidth, _topControlsView.bounds.size.height);
    } else {
        self.zoomButton.frame = CGRectMake(self.frame.size.width - zoomButtonWidth, 0.f, zoomButtonWidth, _topControlsView.bounds.size.height);
    }

    // volume control is always right
    self.volumeControl.frame = CGRectMake(width + self.bottomControlsView.frame.origin.x - kControlWidth - outerPadding, self.bottomControlsView.frame.origin.y + buttonTopPadding, kControlWidth, controlsViewHeight);
    rightEdge = self.volumeControl.frame.origin.x - self.bottomControlsView.frame.origin.x;

    // we always position the airplay button, but only update the left edge when the button is visible
    // this is a workaround for a layout bug I can't remember
    self.airPlayButtonContainer.frame = CGRectMake(rightEdge-kControlWidth, buttonTopPadding + 2.f, kControlWidth, controlsViewHeight);
    if (self.isAirPlayButtonVisible) {
        rightEdge = self.airPlayButtonContainer.frame.origin.x;
    } 

    // skip buttons can be shown or hidden
    self.rewindButton.hidden = !displaySkipButtons;
    self.forwardButton.hidden = !displaySkipButtons;

    if (displaySkipButtons) {
        self.rewindButton.frame = CGRectMake(leftEdge, buttonTopPadding, kControlWidth, controlsViewHeight);
        self.forwardButton.frame = CGRectMake(rightEdge - kControlWidth, buttonTopPadding, kControlWidth, controlsViewHeight);

        leftEdge = self.rewindButton.frame.origin.x + self.rewindButton.frame.size.width;
        rightEdge = self.forwardButton.frame.origin.x;
    }

    self.scrubber.frame = CGRectMake(leftEdge, buttonTopPadding + 12.f, rightEdge - leftEdge, 20.f);
    self.scrubber.hidden = self.scrubberHidden;

    self.currentTimeLabel.frame = CGRectMake(leftEdge + 10.f, self.scrubber.frame.origin.y, 60.f, 20.f);
    self.currentTimeLabel.textAlignment = UITextAlignmentLeft;

    self.remainingTimeLabel.frame = CGRectMake(rightEdge - 70.f, self.scrubber.frame.origin.y, 60.f, 20.f);
    self.remainingTimeLabel.textAlignment = UITextAlignmentRight;
}

@end
