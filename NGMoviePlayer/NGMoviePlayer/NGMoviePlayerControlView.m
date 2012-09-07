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
#define kBottomControlHorizontalPadding        (self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f)
#define kMinWidthToDisplaySkipButtons          420.f


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
}

@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) MPVolumeView *airPlayButton;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;
@property (nonatomic, strong) UIView *topButtonContainer;
@property (nonatomic, strong) UIImage *bottomControlFullscreenImage;
@property (nonatomic, readonly, getter = isAirPlayButtonVisible) BOOL airPlayButtonVisible;
@property (nonatomic, readonly, getter = isPlayingLivestream) BOOL playingLivestream;
@property (nonatomic, strong) NSDictionary *controls;

- (CGFloat)controlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle;
- (void)setupScrubber:(NGScrubber *)scrubber controlStyle:(NGMoviePlayerControlStyle)controlStyle;

- (void)handlePlayPauseButtonPress:(id)sender;
- (void)handleRewindButtonTouchDown:(id)sender;
- (void)handleRewindButtonTouchUp:(id)sender;
- (void)handleForwardButtonTouchDown:(id)sender;
- (void)handleForwardButtonTouchUp:(id)sender;
- (void)handleZoomButtonPress:(id)sender;

- (void)handleBeginScrubbing:(id)sender;
- (void)handleScrubbingValueChanged:(id)sender;
- (void)handleEndScrubbing:(id)sender;

- (void)handleVolumeChanged:(id)sender;

@end


@implementation NGMoviePlayerControlView

@synthesize delegate = _delegate;
@synthesize controlStyle = _controlStyle;
@synthesize scrubber = _scrubber;
@synthesize scrubberFillColor = _scrubberFillColor;
@synthesize topControlsView = _topControlsView;
@synthesize bottomControlsView = _bottomControlsView;
@synthesize playPauseButton = _playPauseButton;
@synthesize rewindButton = _rewindButton;
@synthesize forwardButton = _forwardButton;
@synthesize airPlayButton = _airPlayButton;
@synthesize zoomButton = _zoomButton;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize volumeControl = _volumeControl;
@synthesize topButtonContainer = _topButtonContainer;
@synthesize topControlsViewButtonPadding = _topControlsViewButtonPadding;
@synthesize zoomOutButtonPosition = _zoomOutButtonPosition;
@synthesize layoutSubviewsBlock = _layoutSubviewsBlock;
@synthesize controls = _controls;
@synthesize bottomControlFullscreenImage = _bottomControlFullscreenImage;
@synthesize scrubberHidden = _scrubberHidden;
@synthesize skipButtonsHidden = _skipButtonsHidden;

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
            _airPlayButton = [[MPVolumeView alloc] initWithFrame:(CGRect) { .size = CGSizeMake(40.f, 40.f) }];
            _airPlayButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
            _airPlayButton.showsRouteButton = YES;
            _airPlayButton.showsVolumeSlider = NO;
            [_bottomControlsView addSubview:_airPlayButton];
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
                     _airPlayButton, NGMoviePlayerControlViewAirPlayButtonKey,
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
    // otherwise the airPlayButton isn't positioned correctly on first show
    if (alpha > 0.f) {
        [self setNeedsLayout];
    }

    [super setAlpha:alpha];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat controlsViewHeight = [self controlsViewHeightForControlStyle:self.controlStyle];

    _topControlsView.frame = CGRectMake(0.f, (self.controlStyle == NGMoviePlayerControlStyleFullscreen ? 20.f : 0.f), self.bounds.size.width, [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline]);
    _bottomControlsView.frame = CGRectMake(kBottomControlHorizontalPadding, self.bounds.size.height-controlsViewHeight, self.bounds.size.width - kBottomControlHorizontalPadding*2.f, controlsViewHeight-kBottomControlHorizontalPadding);

    if (self.layoutSubviewsBlock) {
        self.layoutSubviewsBlock(self.controlStyle, self.controls);
    } else {
        [self layoutSubviewsForControlStyle:self.controlStyle];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerControlView
////////////////////////////////////////////////////////////////////////

// TODO: Fix me, I'm horrible!
- (void)layoutSubviewsForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    CGFloat controlsViewHeight = [self controlsViewHeightForControlStyle:self.controlStyle];
    CGFloat inlineControlsViewHeight = [self controlsViewHeightForControlStyle:NGMoviePlayerControlStyleInline];
    CGFloat buttonTopPadding = 23.f;

    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        ((UIImageView *)self.bottomControlsView).image = self.bottomControlFullscreenImage;
        self.bottomControlsView.backgroundColor = [UIColor clearColor];

        if (self.isAirPlayButtonVisible) {
            self.airPlayButton.frame = CGRectMake(_bottomControlsView.frame.size.width - 45.f, buttonTopPadding + 10.f, 40.f, 40.f);
        } else {
            self.airPlayButton.frame = CGRectMake(_bottomControlsView.frame.size.width - 5.f, buttonTopPadding + 10.f, 0.f, 0.f);
        }

        BOOL displaySkipButtons = !self.skipButtonsHidden && (_bottomControlsView.frame.size.width > kMinWidthToDisplaySkipButtons);
        self.rewindButton.hidden = !displaySkipButtons;
        self.forwardButton.hidden = !displaySkipButtons;

        self.playPauseButton.frame = CGRectMake(5.f, buttonTopPadding, 40.f, 40.f);
        self.volumeControl.frame = CGRectMake(self.airPlayButton.frame.origin.x - 20.f, _bottomControlsView.frame.origin.y + buttonTopPadding, 40.f, 40.f);
        self.rewindButton.frame = CGRectMake(self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width, buttonTopPadding, 40.f, 40.f);
        self.forwardButton.frame = CGRectMake(self.volumeControl.frame.origin.x - 55.f, buttonTopPadding, 40.f, 40.f);

        CGFloat scrubberLeftOrigin = (displaySkipButtons ? self.rewindButton.frame.origin.x + self.rewindButton.frame.size.width : self.playPauseButton.frame.origin.x + self.playPauseButton.frame.size.width);
        CGFloat scrubberRightOrigin = (displaySkipButtons ? self.forwardButton.frame.origin.x : self.volumeControl.frame.origin.x - 20.f);
        self.scrubber.frame = CGRectMake(scrubberLeftOrigin, buttonTopPadding + 10.f, scrubberRightOrigin - scrubberLeftOrigin, 20.f);
        self.scrubber.hidden = self.scrubberHidden;

        self.currentTimeLabel.frame = CGRectMake(scrubberLeftOrigin + 10.f, self.scrubber.frame.origin.y, 55.f, 20.f);
        self.currentTimeLabel.textAlignment = UITextAlignmentLeft;

        self.remainingTimeLabel.frame = CGRectMake(scrubberRightOrigin - 65.f, self.scrubber.frame.origin.y, 55.f, 20.f);
        self.remainingTimeLabel.textAlignment = UITextAlignmentRight;

        UIImage *zoomButtonImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/zoomOut"];
        self.zoomButton.frame = (self.zoomOutButtonPosition == NGMoviePlayerControlViewZoomOutButtonPositionRight ?
                                 CGRectMake(self.topControlsView.bounds.size.width - zoomButtonImage.size.width, 0.f,
                                            zoomButtonImage.size.width, _topControlsView.bounds.size.height) :
                                 CGRectMake(0.f, 0.f, zoomButtonImage.size.width, _topControlsView.bounds.size.height));
        [self.zoomButton setImage:zoomButtonImage forState:UIControlStateNormal];
    } else {
        ((UIImageView *)self.bottomControlsView).image = nil;
        self.bottomControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:kControlAlphaValue];
        self.rewindButton.hidden = YES;
        self.forwardButton.hidden = YES;

        self.volumeControl.frame = CGRectMake(self.bounds.size.width-controlsViewHeight, self.bottomControlsView.frame.origin.y, controlsViewHeight,controlsViewHeight);
        self.zoomButton.frame = CGRectMake(self.topControlsView.bounds.size.width - controlsViewHeight, 0.f, controlsViewHeight, controlsViewHeight);
        [self.zoomButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomIn"] forState:UIControlStateNormal];

        CGFloat airPlayButtonOffset = 0.f;

        self.airPlayButton.frame = CGRectMake(self.bounds.size.width-2*controlsViewHeight, 10.f, controlsViewHeight, controlsViewHeight);

        if (self.isAirPlayButtonVisible) {
            airPlayButtonOffset = self.airPlayButton.frame.size.width + 18.f;
        }

        self.playPauseButton.frame = CGRectMake(0.f, 0.f, controlsViewHeight, controlsViewHeight);

        self.currentTimeLabel.frame = CGRectMake(20.f, 0.f, 55.f, controlsViewHeight);
        self.currentTimeLabel.textAlignment = UITextAlignmentRight;
        self.scrubber.frame = CGRectMake(80.f, 0.f, self.bottomControlsView.bounds.size.width - 160.f - airPlayButtonOffset, controlsViewHeight);
        self.remainingTimeLabel.frame = CGRectMake(self.scrubber.frame.origin.x + self.scrubber.frame.size.width + 5.f, 0.f, 55.f, controlsViewHeight);
        self.remainingTimeLabel.textAlignment = UITextAlignmentLeft;
    }

    // center top controls
    self.topButtonContainer.frame = CGRectMake(MAX((self.topControlsView.frame.size.width - self.topButtonContainer.frame.size.width)/2.f, 0.f),
                                               0.f,
                                               self.topButtonContainer.frame.size.width,
                                               inlineControlsViewHeight);
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
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (CGFloat)controlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        return 85.f + kBottomControlHorizontalPadding;
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

@end
