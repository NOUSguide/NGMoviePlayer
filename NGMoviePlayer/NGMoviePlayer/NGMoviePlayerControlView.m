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

@interface NGMoviePlayerControlView ()

@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;

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
@synthesize volumeView = _volumeView;
@synthesize zoomButton = _zoomButton;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize volumeControl = _volumeControl;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _scrubberFillColor = [UIColor grayColor];
        
        _topControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _topControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
        [self addSubview:_topControlsView];
        
        _bottomControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
        [self addSubview:_bottomControlsView];
        
        // We use the MPVolumeView just for displaying the AirPlay icon
        if ([AVPlayer instancesRespondToSelector:@selector(allowsAirPlayVideo)]) {
            _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(_bottomControlsView.bounds.size.width-80.f, 10.f, 29.f, 20.f)];
            _volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _volumeView.showsVolumeSlider = NO;
            [_bottomControlsView addSubview:_volumeView];
        }
        
        _volumeControl = [[NGVolumeControl alloc] initWithFrame:CGRectZero];
        [_volumeControl addTarget:self action:@selector(handleVolumeChanged:) forControlEvents:UIControlEventValueChanged];
        // volume control needs to get added to self instead of bottomControlView because otherwise the expanded slider
        // doesn't receive any touch events
        [self addSubview:_volumeControl];
        
        _rewindButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _rewindButton.frame = CGRectMake(10.f, 10.f, 20.f, 20.f);
        _rewindButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _rewindButton.showsTouchWhenHighlighted = YES;
        [_rewindButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/rewind"] forState:UIControlStateNormal];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_rewindButton addTarget:self action:@selector(handleRewindButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_rewindButton];
        
        _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _forwardButton.frame = CGRectMake(90.f, 10.f, 20.f, 20.f);
        _forwardButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _forwardButton.showsTouchWhenHighlighted = YES;
        [_forwardButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/forward"] forState:UIControlStateNormal];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchDown:) forControlEvents:UIControlEventTouchDown];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpInside];
        [_forwardButton addTarget:self action:@selector(handleForwardButtonTouchUp:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_forwardButton];
        
        _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playPauseButton.contentMode = UIViewContentModeCenter;
        _playPauseButton.showsTouchWhenHighlighted = YES;
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
        _currentTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _currentTimeLabel.textAlignment = UITextAlignmentRight;
        _currentTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin;
        [_bottomControlsView addSubview:_currentTimeLabel];
        
        _remainingTimeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _remainingTimeLabel.backgroundColor = [UIColor clearColor];
        _remainingTimeLabel.textColor = [UIColor whiteColor];
        _remainingTimeLabel.font = [UIFont boldSystemFontOfSize:13.];
        _remainingTimeLabel.textAlignment = UITextAlignmentLeft;
        _remainingTimeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [_bottomControlsView addSubview:_remainingTimeLabel];
        
        [self setupScrubber:_scrubber controlStyle:_controlStyle];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat controlsViewHeight = [self controlsViewHeightForControlStyle:self.controlStyle];
    
    _topControlsView.frame = CGRectMake(0.f, 0.f, self.bounds.size.width, controlsViewHeight);
    _bottomControlsView.frame = CGRectMake(0.f, self.bounds.size.height-controlsViewHeight, self.bounds.size.width, controlsViewHeight);
    
    if (self.controlStyle == NGMoviePlayerControlStyleFullscreen) {
        self.rewindButton.hidden = NO;
        self.forwardButton.hidden = NO;
        
        self.currentTimeLabel.frame = CGRectMake(10.f, 40.f, 55.f, 20.f);
        self.currentTimeLabel.textAlignment = UITextAlignmentLeft;
        
        self.remainingTimeLabel.frame = CGRectMake(self.bottomControlsView.bounds.size.width-65.f, 40.f, 55.f, 20.f);
        self.remainingTimeLabel.textAlignment = UITextAlignmentRight;
        
        self.playPauseButton.frame = CGRectMake(50.f, 10.f, 20.f, 20.f);
        self.scrubber.frame = CGRectMake(0.f, 40.f, self.bottomControlsView.bounds.size.width, 20.f);
        self.volumeControl.frame = CGRectMake(self.bounds.size.width-40.f, self.bottomControlsView.frame.origin.y, 40.f,40.f);
        self.zoomButton.frame = CGRectMake(self.topControlsView.bounds.size.width - controlsViewHeight, 0.f, controlsViewHeight, controlsViewHeight);
        [self.zoomButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomIn"] forState:UIControlStateNormal];
    } else {
        self.rewindButton.hidden = YES;
        self.forwardButton.hidden = YES;
        
        self.playPauseButton.frame = CGRectMake(0.f, 0.f, controlsViewHeight, controlsViewHeight);
        
        self.currentTimeLabel.frame = CGRectMake(20.f, 0.f, 55.f, controlsViewHeight);
        self.currentTimeLabel.textAlignment = UITextAlignmentRight;
        
        self.remainingTimeLabel.frame = CGRectMake(self.bottomControlsView.bounds.size.width-75.f, 0.f, 55.f, controlsViewHeight);
        self.remainingTimeLabel.textAlignment = UITextAlignmentLeft;
        
        self.scrubber.frame = CGRectMake(80.f, 0.f, self.bottomControlsView.bounds.size.width-160.f, controlsViewHeight);
        self.volumeControl.frame = CGRectMake(self.bounds.size.width-controlsViewHeight, self.bottomControlsView.frame.origin.y, controlsViewHeight,controlsViewHeight);
        self.zoomButton.frame = CGRectMake(self.topControlsView.bounds.size.width - controlsViewHeight, 0.f, controlsViewHeight, controlsViewHeight);
        [self.zoomButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomOut"] forState:UIControlStateNormal];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerControlView
////////////////////////////////////////////////////////////////////////

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle != _controlStyle) {
        _controlStyle = controlStyle;
        
        [self setupScrubber:self.scrubber controlStyle:controlStyle];
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

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (CGFloat)controlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        return 70.f;
    } else {
        return 40.f;
    }
}

- (void)setupScrubber:(NGScrubber *)scrubber controlStyle:(NGMoviePlayerControlStyle)controlStyle {
    CGFloat height = 20.f;
    
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {        
        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberKnobFullscreen"] 
                       forState:UIControlStateNormal];
    } else {
        height = 10.f;

        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberKnob"] 
                       forState:UIControlStateNormal];
    }
    
    //Build a rect of appropriate size at origin 0,0
    CGRect fillRect = CGRectMake(0.f,0.f,1.f,height);
    
    // create minimum track image
    UIGraphicsBeginImageContext(CGSizeMake(1.f, height));
    CGContextRef currentContext = UIGraphicsGetCurrentContext();
    //Set the fill color
    CGContextSetFillColorWithColor(currentContext, self.scrubberFillColor.CGColor);
    //Fill the color
    CGContextFillRect(currentContext, fillRect);
    //Snap the picture and close the context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [scrubber setMinimumTrackImage:image forState:UIControlStateNormal];
    
    // create maximum track image
    UIGraphicsBeginImageContext(CGSizeMake(1.f, height));
    currentContext = UIGraphicsGetCurrentContext();
    //Set the fill color
    CGContextSetFillColorWithColor(currentContext, [UIColor colorWithWhite:1.f alpha:.2f].CGColor);
    //Fill the color
    CGContextFillRect(currentContext, fillRect);
    //Snap the picture and close the context
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [scrubber setMaximumTrackImage:image forState:UIControlStateNormal];
    
    // force re-draw of playable value of scrubber
    scrubber.playableValue = scrubber.playableValue;
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
