//
//  NGMoviePlayerControlView.m
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerControlView+NGPrivate.h"
#import "NGMoviePlayerControlActionDelegate.h"
#import "NGScrubber.h"
#import "NGVolumeControl.h"
#import "NGMoviePlayerFunctions.h"
#import "NGMoviePlayerLayout.h"


@interface NGMoviePlayerControlView () {
    BOOL _statusBarHidden;
}

@property (nonatomic, readonly, getter = isPlayingLivestream) BOOL playingLivestream;

// Properties from NGMoviePlayerControlView+NGPrivate
@property (nonatomic, strong) NGMoviePlayerLayout *layout;
@property (nonatomic, strong, readwrite) UIView *topControlsView;
@property (nonatomic, strong, readwrite) UIView *bottomControlsView;
@property (nonatomic, strong, readwrite) UIView *topControlsContainerView;
@property (nonatomic, strong, readwrite) UIButton *playPauseControl;
@property (nonatomic, strong, readwrite) NGScrubber *scrubberControl;
@property (nonatomic, strong, readwrite) UIButton *rewindControl;
@property (nonatomic, strong, readwrite) UIButton *forwardControl;
@property (nonatomic, strong, readwrite) UILabel *currentTimeLabel;
@property (nonatomic, strong, readwrite) UILabel *remainingTimeLabel;
@property (nonatomic, strong, readwrite) NGVolumeControl *volumeControl;
@property (nonatomic, strong, readwrite) UIControl *airPlayControlContainer;
@property (nonatomic, strong, readwrite) MPVolumeView *airPlayControl;
@property (nonatomic, strong, readwrite) UIButton *zoomControl;

@end


@implementation NGMoviePlayerControlView

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _topControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _topControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6f];
        _topControlsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self addSubview:_topControlsView];

        _topControlsContainerView = [[UIView alloc] initWithFrame:CGRectZero];
        _topControlsContainerView.backgroundColor = [UIColor clearColor];
        [_topControlsView addSubview:_topControlsContainerView];

        _bottomControlsView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _bottomControlsView.userInteractionEnabled = YES;
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
            _airPlayControl = [[MPVolumeView alloc] initWithFrame:(CGRect) { .size = CGSizeMake(38.f, 22.f) }];
            _airPlayControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            _airPlayControl.contentMode = UIViewContentModeCenter;
            _airPlayControl.showsRouteButton = YES;
            _airPlayControl.showsVolumeSlider = NO;

            _airPlayControlContainer = [[UIControl alloc] initWithFrame:CGRectMake(0.f, 0.f, 60.f, 44.f)];
            _airPlayControl.center = CGPointMake(_airPlayControlContainer.frame.size.width/2.f, _airPlayControlContainer.frame.size.height/2.f - 2.f);
            [_airPlayControlContainer addTarget:self action:@selector(handleAirPlayButtonPress:) forControlEvents:UIControlEventTouchUpInside];
            [_airPlayControlContainer addSubview:_airPlayControl];
            [_bottomControlsView addSubview:_airPlayControlContainer];
        }

        _rewindControl = [UIButton buttonWithType:UIButtonTypeCustom];
        _rewindControl.frame = CGRectMake(60.f, 10.f, 40.f, 40.f);
        _rewindControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _rewindControl.showsTouchWhenHighlighted = YES;
        [_rewindControl setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/prevtrack"] forState:UIControlStateNormal];
        [_rewindControl addTarget:self action:@selector(handleRewindButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_rewindControl addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_rewindControl addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_rewindControl];

        _forwardControl = [UIButton buttonWithType:UIButtonTypeCustom];
        _forwardControl.frame = _rewindControl.frame;
        _forwardControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _forwardControl.showsTouchWhenHighlighted = YES;
        [_forwardControl setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/nexttrack"] forState:UIControlStateNormal];
        [_forwardControl addTarget:self action:@selector(handleForwardButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_forwardControl addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_forwardControl addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_forwardControl];

        _playPauseControl = [UIButton buttonWithType:UIButtonTypeCustom];
        _playPauseControl.frame = CGRectMake(0.f, 0.f, 44.f, 44.f);
        _playPauseControl.contentMode = UIViewContentModeCenter;
        _playPauseControl.showsTouchWhenHighlighted = YES;
        _playPauseControl.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        [_playPauseControl addTarget:self action:@selector(handlePlayPauseButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomControlsView addSubview:_playPauseControl];

        _scrubberControl = [[NGScrubber alloc] initWithFrame:CGRectZero];
        _scrubberControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_scrubberControl addTarget:self action:@selector(handleBeginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [_scrubberControl addTarget:self action:@selector(handleScrubbingValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_scrubberControl addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [_scrubberControl addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_scrubberControl];

        _zoomControl = [UIButton buttonWithType:UIButtonTypeCustom];
        _zoomControl.showsTouchWhenHighlighted = YES;
        _zoomControl.contentMode = UIViewContentModeCenter;
        [_zoomControl addTarget:self action:@selector(handleZoomButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_topControlsView addSubview:_zoomControl];

        _currentTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _currentTimeLabel.backgroundColor = [UIColor clearColor];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.shadowColor = [UIColor blackColor];
        _currentTimeLabel.shadowOffset = CGSizeMake(0.f, 1.f);
        _currentTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _currentTimeLabel.textAlignment = NSTextAlignmentRight;
        _currentTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [_bottomControlsView addSubview:_currentTimeLabel];

        _remainingTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _remainingTimeLabel.backgroundColor = [UIColor clearColor];
        _remainingTimeLabel.textColor = [UIColor whiteColor];
        _remainingTimeLabel.shadowColor = [UIColor blackColor];
        _remainingTimeLabel.shadowOffset = CGSizeMake(0.f, 1.f);
        _remainingTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _remainingTimeLabel.textAlignment = NSTextAlignmentLeft;
        _remainingTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_bottomControlsView addSubview:_remainingTimeLabel];

        _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;

        _controlStyle = NGMoviePlayerControlStyleInline;
        _scrubbingTimeDisplay = NGMoviePlayerControlScrubbingTimeDisplayPopup;
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

    [self.layout layoutTopControlsViewWithControlStyle:self.controlStyle];
    [self.layout layoutBottomControlsViewWithControlStyle:self.controlStyle];
    [self.layout layoutControlsWithControlStyle:self.controlStyle];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.volumeControl.expanded) {
        return [super pointInside:point withEvent:event];
    }

    BOOL insideTopControlsView = CGRectContainsPoint(self.topControlsView.frame, point);
    BOOL insideBottomControlsView = CGRectContainsPoint(self.bottomControlsView.frame, point);

    return  insideTopControlsView || insideBottomControlsView;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerControlView
////////////////////////////////////////////////////////////////////////

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    _controlStyle = controlStyle;
    [self.layout updateControlStyle:controlStyle];
}

- (void)setLayout:(NGMoviePlayerLayout *)layout {
    if (layout != _layout) {
        _layout = layout;
    }

    [layout updateControlStyle:self.controlStyle];
}

- (void)setScrubbingTimeDisplay:(NGMoviePlayerControlScrubbingTimeDisplay)scrubbingTimeDisplay {
    if (scrubbingTimeDisplay != _scrubbingTimeDisplay) {
        _scrubbingTimeDisplay = scrubbingTimeDisplay;

        self.scrubberControl.showPopupDuringScrubbing = (scrubbingTimeDisplay == NGMoviePlayerControlScrubbingTimeDisplayPopup);
    }
}

- (void)setPlayableDuration:(NSTimeInterval)playableDuration {
    self.scrubberControl.playableValue = playableDuration;
}

- (NSTimeInterval)playableDuration {
    return self.scrubberControl.playableValue;
}

- (void)updateScrubberWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    self.currentTimeLabel.text = NGMoviePlayerGetTimeFormatted(currentTime);
    self.remainingTimeLabel.text = NGMoviePlayerGetRemainingTimeFormatted(currentTime, duration);

    [self.scrubberControl setMinimumValue:0.];
    [self.scrubberControl setMaximumValue:duration];
    [self.scrubberControl setValue:currentTime];
}

- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying {
    UIImage *image = nil;

    if (self.controlStyle == NGMoviePlayerControlStyleInline) {
        image = isPlaying ? [UIImage imageNamed:@"NGMoviePlayer.bundle/pause"] : [UIImage imageNamed:@"NGMoviePlayer.bundle/play"];
    } else {
        image = isPlaying ? [UIImage imageNamed:@"NGMoviePlayer.bundle/pauseFullscreen"] : [UIImage imageNamed:@"NGMoviePlayer.bundle/playFullscreen"];
    }

    [self.playPauseControl setImage:image forState:UIControlStateNormal];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

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
    if (self.scrubbingTimeDisplay == NGMoviePlayerControlScrubbingTimeDisplayCurrentTime) {
        self.currentTimeLabel.text = NGMoviePlayerGetTimeFormatted(self.scrubberControl.value);
        self.remainingTimeLabel.text = NGMoviePlayerGetRemainingTimeFormatted(self.scrubberControl.value, self.scrubberControl.maximumValue);
    }

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
    for (UIView *subview in self.airPlayControl.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;

            [button sendActionsForControlEvents:UIControlEventTouchUpInside];
        }
    }

    [self.delegate moviePlayerControl:self.airPlayControl didPerformAction:NGMoviePlayerControlActionAirPlayMenuActivated];
}

@end
