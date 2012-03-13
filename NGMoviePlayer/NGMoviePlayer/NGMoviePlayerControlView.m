//
//  NGMoviePlayerControlView.m
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerControlActionDelegate.h"
#import "NGSlider.h"

@interface NGMoviePlayerControlView ()

@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;

- (CGFloat)controlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle;
- (void)setupScrubber:(NGSlider *)scrubber controlStyle:(NGMoviePlayerControlStyle)controlStyle;

- (void)handlePlayPauseButtonPress:(id)sender;
- (void)handleRewindButtonTouchDown:(id)sender;
- (void)handleRewindButtonTouchUp:(id)sender;
- (void)handleForwardButtonTouchDown:(id)sender;
- (void)handleForwardButtonTouchUp:(id)sender;
- (void)handleZoomButtonPress:(id)sender;

- (void)handleBeginScrubbing:(id)sender;
- (void)handleScrubbingValueChanged:(id)sender;
- (void)handleEndScrubbing:(id)sender;

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

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        _scrubberFillColor = [UIColor purpleColor];
        
        _topControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _topControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
        [self addSubview:_topControlsView];
        
        _bottomControlsView = [[UIView alloc] initWithFrame:CGRectZero];
        _bottomControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
        [self addSubview:_bottomControlsView];
        
        _volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(_bottomControlsView.bounds.size.width-80.f, 10.f, 29.f, 20.f)];
        _volumeView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        // iOS 4.2 up
        if ([_volumeView respondsToSelector:@selector(setShowsVolumeSlider:)]) {
            _volumeView.showsVolumeSlider = NO;
        }
        [_bottomControlsView addSubview:_volumeView];
        
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
        _playPauseButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
        _playPauseButton.showsTouchWhenHighlighted = YES;
        [_playPauseButton addTarget:self action:@selector(handlePlayPauseButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomControlsView addSubview:_playPauseButton];
        
        _scrubber = [[NGSlider alloc] initWithFrame:CGRectZero];
        _scrubber.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [_scrubber addTarget:self action:@selector(handleBeginScrubbing:) forControlEvents:UIControlEventTouchDown];
        [_scrubber addTarget:self action:@selector(handleScrubbingValueChanged:) forControlEvents:UIControlEventValueChanged];
        [_scrubber addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpInside];
        [_scrubber addTarget:self action:@selector(handleEndScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
        [_bottomControlsView addSubview:_scrubber];
        
        _zoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _zoomButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
        _zoomButton.showsTouchWhenHighlighted = YES;
        [_zoomButton addTarget:self action:@selector(handleZoomButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomControlsView addSubview:_zoomButton];
        
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
        self.zoomButton.frame = CGRectMake(self.bottomControlsView.bounds.size.width-30.f, 12.f, 29.f, 16.f);
        [self.zoomButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/zoomIn"] forState:UIControlStateNormal];
    } else {
        self.rewindButton.hidden = YES;
        self.forwardButton.hidden = YES;
        
        self.currentTimeLabel.frame = CGRectMake(30.f, 8.f, 55.f, 25.f);
        self.currentTimeLabel.textAlignment = UITextAlignmentRight;
        
        self.remainingTimeLabel.frame = CGRectMake(self.bottomControlsView.bounds.size.width-85.f, 8.f, 55.f, 25.f);
        self.remainingTimeLabel.textAlignment = UITextAlignmentLeft;
        
        self.playPauseButton.frame = CGRectMake(10.f, 10.f, 20.f, 20.f);
        self.scrubber.frame = CGRectMake(90.f, 9.f, self.bottomControlsView.bounds.size.width-180.f, 24.f);
        self.zoomButton.frame = CGRectMake(self.bottomControlsView.bounds.size.width-30.f, 12.f, 29.f, 16.f);
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

- (void)updateScrubberWithCurrentTime:(NSInteger)currentTime duration:(NSInteger)duration {
    NSInteger seconds = currentTime % 60;
    NSInteger minutes = currentTime / 60;
    NSInteger hours = minutes / 60;
    
    NSInteger currentDurationSeconds = duration-currentTime;
    NSInteger durationSeconds = currentDurationSeconds % 60;
    NSInteger durationMinutes = currentDurationSeconds / 60;
    NSInteger durationHours = durationMinutes / 60;
    
    if (durationSeconds < 0) {
        durationSeconds = 0;
    }
    
    if (hours > 0) {
        [self.currentTimeLabel setText:[NSString stringWithFormat:@"%02d:%02d:%02d", hours, minutes, seconds]];
    } else {
        [self.currentTimeLabel setText:[NSString stringWithFormat:@"%d:%02d", minutes, seconds]];
    }
    
    if (durationHours > 0) {
        [self.remainingTimeLabel setText:[NSString stringWithFormat:@"-%02d:%02d:%02d", durationHours, durationMinutes, durationSeconds]];
    } else {
        [self.remainingTimeLabel setText:[NSString stringWithFormat:@"-%d:%02d", durationMinutes, durationSeconds]];
    }
    
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

- (void)setupScrubber:(NGSlider *)scrubber controlStyle:(NGMoviePlayerControlStyle)controlStyle {
    scrubber.alpha = 0.75f;
    
    if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
        //Build a rect of appropriate size at origin 0,0
        CGRect fillRect = CGRectMake(0.f,0.f,1.f,20.f);
        
        //Create a context of the appropriate size
        UIGraphicsBeginImageContext(CGSizeMake(1.f, 20.f));
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        //Set the fill color
        CGContextSetFillColorWithColor(currentContext, self.scrubberFillColor.CGColor);
        //Fill the color
        CGContextFillRect(currentContext, fillRect);
        //Snap the picture and close the context
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [scrubber setMinimumTrackImage:image forState:UIControlStateNormal];
        
        //Create a context of the appropriate size
        UIGraphicsBeginImageContext(CGSizeMake(1.f, 20.f));
        currentContext = UIGraphicsGetCurrentContext();
        //Set the fill color
        CGContextSetFillColorWithColor(currentContext, [UIColor colorWithWhite:1.f alpha:.2f].CGColor);
        //Fill the color
        CGContextFillRect(currentContext, fillRect);
        //Snap the picture and close the context
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [scrubber setMaximumTrackImage:image forState:UIControlStateNormal];
        
        //Create a context of the appropriate size
        UIGraphicsBeginImageContext(CGSizeMake(1, 1));
        //Snap the picture and close the context
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [scrubber setThumbImage:image forState:UIControlStateNormal];
    } else {
        [scrubber setMinimumTrackImage:[[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberFilled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 4.f, 0.f, 0.f)] 
                              forState:UIControlStateNormal];
        [scrubber setMaximumTrackImage:[[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberUnfilled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 4.f, 0.f, 0.f)] 
                              forState:UIControlStateNormal];
        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/scrubberKnob"] 
                       forState:UIControlStateNormal];
        
    }
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

@end
