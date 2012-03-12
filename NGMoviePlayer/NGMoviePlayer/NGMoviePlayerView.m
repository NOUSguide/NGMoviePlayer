#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"
#import "NGSlider.h"


#define kNGFadeDuration             0.4
#define kNGControlsViewHeight      40.f // Fullscreen: 70.f


static char playerLayerReadyForDisplayContext;


@interface NGMoviePlayerView () {
    BOOL _statusBarVisible;
    BOOL _readyForDisplayTriggered;
}

@property (nonatomic, strong, readwrite) UIView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIView *topControlsView;
@property (nonatomic, strong) UIView *bottomControlsView;
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UIButton *rewindButton;
@property (nonatomic, strong) UIButton *forwardButton;
@property (nonatomic, strong) MPVolumeView *volumeView;
@property (nonatomic, strong) UIButton *zoomButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;

@property (nonatomic, strong) UIWindow *externalWindow;

- (void)setup;
- (void)setupScrubber:(NGSlider *)scrubber fullscreen:(BOOL)fullscreen;
- (void)updateUI;

// methods to update the UI to reflect current state
- (void)updateScrubberWithCurrentTime:(NSInteger)currentTime duration:(NSInteger)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

@synthesize controlsView = _controlsView;
@synthesize scrubber = _scrubber;
@synthesize placeholderView = _placeholderView;
@synthesize topControlsView = _topControlsView;
@synthesize bottomControlsView = _bottomControlsView;
@synthesize controlsVisible = _controlsVisible;
@synthesize fullscreen = _fullscreen;
@synthesize playerLayerView = _playerLayerView;
@synthesize playPauseButton = _playPauseButton;
@synthesize rewindButton = _rewindButton;
@synthesize forwardButton = _forwardButton;
@synthesize volumeView = _volumeView;
@synthesize zoomButton = _zoomButton;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize scrubberFillColor = _scrubberFillColor;
@synthesize externalWindow = _externalWindow;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor blackColor];
        
        [self setup];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self setup];
    }
    
    return self;
}

- (void)dealloc {
    [self.playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - KVO
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &playerLayerReadyForDisplayContext) {
        BOOL ready = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        
        if (ready && !_readyForDisplayTriggered) {
            _readyForDisplayTriggered = YES;
            
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            
            [animation setFromValue:[NSNumber numberWithFloat:1.]];
            [animation setToValue:[NSNumber numberWithFloat:0.]];
            [animation setDuration:1.];
            
            [self.placeholderView.layer addAnimation:animation forKey:nil];
            self.placeholderView.layer.opacity = 0.f;
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

/*- (void)layoutSubviews {
    [super layoutSubviews];
    
    
}*/

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView Properties
////////////////////////////////////////////////////////////////////////

- (void)setControlsVisible:(BOOL)controlsVisible {
    [self setControlsVisible:controlsVisible animated:NO];
}

- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated {
    if (controlsVisible != _controlsVisible) {
        [self willChangeValueForKey:@"controlsVisible"];
        _controlsVisible = controlsVisible;
        [self didChangeValueForKey:@"controlsVisible"];
        
        if (controlsVisible) {
            [self bringSubviewToFront:self.controlsView];
        }
        
        [UIView animateWithDuration:animated ? kNGFadeDuration : 0.
                              delay:0.
                            options:(UIViewAnimationCurveEaseInOut)
                         animations:^{        
                             self.controlsView.alpha = controlsVisible ? 1.f : 0.f;
                         } completion:nil];
        
        if (self.fullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:(!controlsVisible) withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (void)setFullscreen:(BOOL)fullscreen {
    if (fullscreen != _fullscreen) {
        [self willChangeValueForKey:@"fullscreen"];
        _fullscreen = fullscreen;
        [self didChangeValueForKey:@"fullscreen"];
        
        // hide status bar in fullscreen, restore to previous state
        if (fullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:!_statusBarVisible withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self.playerLayerView layer];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView UI Update
////////////////////////////////////////////////////////////////////////

- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    [self updateScrubberWithCurrentTime:(NSInteger)ceilf(currentTime) duration:(NSInteger)ceilf(duration)];
}

- (void)updateWithPlaybackStatus:(BOOL)isPlaying {
    [self updateButtonsWithPlaybackStatus:isPlaying];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setup {
    _scrubberFillColor = [UIColor purpleColor];
    _controlsVisible = NO;
    _fullscreen = NO;
    _statusBarVisible = ![UIApplication sharedApplication].statusBarHidden;
    _readyForDisplayTriggered = NO;
    
    // Placeholder
    _placeholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/playerBackground"]];
    _placeholderView.frame = self.bounds;
    _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_placeholderView];
    
    // Controls
    _controlsView = [[UIView alloc] initWithFrame:self.bounds];
    _controlsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _topControlsView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, _controlsView.bounds.size.width, kNGControlsViewHeight)];
    _topControlsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
    [_controlsView addSubview:_topControlsView];
    
    _bottomControlsView = [[UIView alloc] initWithFrame:CGRectMake(0.f, _controlsView.bounds.size.height-kNGControlsViewHeight, _controlsView.bounds.size.width, kNGControlsViewHeight)];
    _bottomControlsView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _bottomControlsView.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.4f];
    [_controlsView addSubview:_bottomControlsView];
    
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
    [_rewindButton addTarget:self action:@selector(beginSkippingBackwards:) forControlEvents:UIControlEventTouchDown];
    [_rewindButton addTarget:self action:@selector(endSkipping:) forControlEvents:UIControlEventTouchUpInside];
    [_rewindButton addTarget:self action:@selector(endSkipping:) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomControlsView addSubview:_rewindButton];
    
    _forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _forwardButton.frame = CGRectMake(90.f, 10.f, 20.f, 20.f);
    _forwardButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _forwardButton.showsTouchWhenHighlighted = YES;
    [_forwardButton setImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/forward"] forState:UIControlStateNormal];
    [_forwardButton addTarget:self action:@selector(beginSkippingForward:) forControlEvents:UIControlEventTouchDown];
    [_forwardButton addTarget:self action:@selector(endSkipping:) forControlEvents:UIControlEventTouchUpInside];
    [_forwardButton addTarget:self action:@selector(endSkipping:) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomControlsView addSubview:_forwardButton];
    
    _playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playPauseButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    _playPauseButton.showsTouchWhenHighlighted = YES;
    [_playPauseButton addTarget:self action:@selector(playPause:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomControlsView addSubview:_playPauseButton];
    
    _scrubber = [[NGSlider alloc] initWithFrame:CGRectZero];
    _scrubber.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_scrubber addTarget:self action:@selector(beginScrubbing:) forControlEvents:UIControlEventTouchDown];
    [_scrubber addTarget:self action:@selector(scrub:) forControlEvents:UIControlEventValueChanged];
    [_scrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpInside];
    [_scrubber addTarget:self action:@selector(endScrubbing:) forControlEvents:UIControlEventTouchUpOutside];
    [_bottomControlsView addSubview:_scrubber];
    
    _zoomButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _zoomButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    _zoomButton.showsTouchWhenHighlighted = YES;
    [_zoomButton addTarget:self action:@selector(zoomButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
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
    
    // Player Layer
    _playerLayerView = [[NGMoviePlayerLayerView alloc] initWithFrame:self.bounds];
    _playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_playerLayerView];
    
    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&playerLayerReadyForDisplayContext];
}

- (void)setupScrubber:(NGSlider *)scrubber fullscreen:(BOOL)fullscreen {
    scrubber.alpha = 0.75f;
    
    if (fullscreen) {
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
        [scrubber setMinimumTrackImage:[[UIImage imageNamed:@"NGMoviePlayer/scrubberFilled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 4.f, 0.f, 0.f)] 
                              forState:UIControlStateNormal];
        [scrubber setMaximumTrackImage:[[UIImage imageNamed:@"NGMoviePlayer/scrubberUnfilled"] resizableImageWithCapInsets:UIEdgeInsetsMake(0.f, 4.f, 0.f, 0.f)] 
                              forState:UIControlStateNormal];
        [scrubber setThumbImage:[UIImage imageNamed:@"NGMoviePlayer/scrubberKnob"] 
                       forState:UIControlStateNormal];
        
    }
}

- (void)updateUI {
    if (self.fullscreen) {
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
    } 
    
    // inline player
    else {
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
    UIImage *image = isPlaying ? [UIImage imageNamed:@"NGMoviePlayer.bundle/play"] : [UIImage imageNamed:@"NGMoviePlayer.bundle/pause"];
    
    [self.playPauseButton setImage:image forState:UIControlStateNormal];
}

@end
