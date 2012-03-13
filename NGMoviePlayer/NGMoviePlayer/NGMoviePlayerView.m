#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"
#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerControlActionDelegate.h"
#import "NGMoviePlayerVideoGravity.h"

#define kNGFadeDuration                     0.4
#define kNGControlVisibilityDuration        4.


@interface NGMoviePlayerView () <UIGestureRecognizerDelegate> {
    BOOL _statusBarVisible;
    BOOL _readyForDisplayTriggered;
    BOOL _shouldHideControls;
}

@property (nonatomic, strong, readwrite) NGMoviePlayerControlView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) UIWindow *externalWindow;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

- (void)setup;
- (void)fadeOutControls;

- (void)handleSingleTap:(UITapGestureRecognizer *)tap;
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap;
- (void)handlePlayButtonPress:(id)sender;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

@synthesize delegate = _delegate;
@synthesize controlsView = _controlsView;
@synthesize controlsVisible = _controlsVisible;
@synthesize playButton = _playButton;
@synthesize playerLayerView = _playerLayerView;
@synthesize placeholderView = _placeholderView;
@synthesize externalWindow = _externalWindow;
@synthesize singleTapGestureRecognizer = _singleTapGestureRecognizer;
@synthesize doubleTapGestureRecognizer = _doubleTapGestureRecognizer;

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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutControls) object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView Properties
////////////////////////////////////////////////////////////////////////

- (void)setDelegate:(id<NGMoviePlayerControlActionDelegate>)delegate {
    if (delegate != _delegate) {
        _delegate = delegate;
    }
    
    self.controlsView.delegate = delegate;
}

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
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutControls) object:nil];
        [UIView animateWithDuration:animated ? kNGFadeDuration : 0.
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{        
                             self.controlsView.alpha = controlsVisible ? 1.f : 0.f;
                         } completion:^(BOOL finished) {
                             [self restartFadeOutControlsViewTimer];
                         }];
        
        if (self.controlStyle == NGMoviePlayerControlStyleFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:(!controlsVisible) withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (void)setPlaceholderView:(UIView *)placeholderView {
    if (placeholderView != _placeholderView) {
        [_placeholderView removeFromSuperview];
        _placeholderView = placeholderView;
        [self addSubview:_placeholderView];
    }
}

- (void)hidePlaceholderViewAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:kNGFadeDuration
                         animations:^{
                             self.placeholderView.alpha = 0.f;
                         } completion:^(BOOL finished) {
                             [self.placeholderView removeFromSuperview];
                             self.placeholderView = nil;
                         }];
    } else {
        [self.placeholderView removeFromSuperview];
        self.placeholderView = nil;
    }
}

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle != self.controlsView.controlStyle) {
        [self willChangeValueForKey:@"controlStyle"];
        self.controlsView.controlStyle = controlStyle;
        [self didChangeValueForKey:@"controlStyle"];
        
        // hide status bar in fullscreen, restore to previous state
        if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else {
            [[UIApplication sharedApplication] setStatusBarHidden:!_statusBarVisible withAnimation:UIStatusBarAnimationFade];
        }
    }
}

- (NGMoviePlayerControlStyle)controlStyle {
    return self.controlsView.controlStyle;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self.playerLayerView layer];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView UI Update
////////////////////////////////////////////////////////////////////////

- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    [self.controlsView updateScrubberWithCurrentTime:(NSInteger)ceilf(currentTime) duration:(NSInteger)ceilf(duration)];
}

- (void)updateWithPlaybackStatus:(BOOL)isPlaying {
    [self.controlsView updateButtonsWithPlaybackStatus:isPlaying];
    
    _shouldHideControls = isPlaying;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Controls
////////////////////////////////////////////////////////////////////////

- (void)stopFadeOutControlsViewTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutControls) object:nil];
}

- (void)restartFadeOutControlsViewTimer {
    [self stopFadeOutControlsViewTimer];
    [self performSelector:@selector(fadeOutControls) withObject:nil afterDelay:kNGControlVisibilityDuration];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizerDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.controlsVisible || self.placeholderView.alpha > 0.f) {
        NSArray *controls = [NSArray arrayWithObjects:self.controlsView.topControlsView, self.controlsView.bottomControlsView, self.playButton, nil];
        
        // We dont want to to hide the controls when we tap em
        for (UIView *view in controls) {
            if (CGRectContainsPoint(view.frame, [touch locationInView:view.superview])) {
                return NO;
            }
        }
    }
    
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setup {
    self.controlStyle = NGMoviePlayerControlStyleInline;
    _controlsVisible = NO;
    _statusBarVisible = ![UIApplication sharedApplication].statusBarHidden;
    _readyForDisplayTriggered = NO;
    
    // Player Layer
    _playerLayerView = [[NGMoviePlayerLayerView alloc] initWithFrame:self.bounds];
    _playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_playerLayerView];
    
    // Controls
    _controlsView = [[NGMoviePlayerControlView alloc] initWithFrame:self.bounds];
    _controlsView.alpha = 0.f;
    [self addSubview:_controlsView];
    
    // Placeholder
    _placeholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/playerBackground"]];
    _placeholderView.frame = self.bounds;
    _placeholderView.userInteractionEnabled = YES;
    _placeholderView.contentMode = UIViewContentModeScaleAspectFill;
    _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIImage *playImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/playVideo"];
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _playButton.frame = (CGRect){.size = playImage.size};
    _playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _playButton.center = CGPointMake(_placeholderView.bounds.size.width/2.f, _placeholderView.bounds.size.height/2.f);
    [_playButton setImage:playImage forState:UIControlStateNormal];
    [_playButton addTarget:self action:@selector(handlePlayButtonPress:) forControlEvents:UIControlEventTouchUpInside];
    [_placeholderView addSubview:_playButton];
    [self addSubview:_placeholderView];
    
    // Gesture Recognizer
    _doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    _doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    _doubleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_doubleTapGestureRecognizer];
    
    _singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapGestureRecognizer];
    _singleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:_singleTapGestureRecognizer];
}

- (void)fadeOutControls {
    if (_shouldHideControls) {
        [self setControlsVisible:NO animated:YES];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        if (self.placeholderView.alpha == 0.f) {
            // Toggle control visibility on single tap
            [self setControlsVisible:!self.controlsVisible animated:YES];
        }
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        if (self.placeholderView.alpha == 0.f) {
            // Toggle video gravity on double tap
            self.playerLayer.videoGravity = NGAVLayerVideoGravityNext(self.playerLayer.videoGravity);
            // BUG: otherwise the video gravity doesn't change immediately
            self.playerLayer.bounds = self.playerLayer.bounds;
        }
    }
}

- (void)handlePlayButtonPress:(id)sender {
    UIActivityIndicatorView *activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    activityView.hidesWhenStopped = YES;
    activityView.center = self.playButton.center;
    activityView.autoresizingMask = self.playButton.autoresizingMask;
    [self.playButton.superview addSubview:activityView];
    [self.playButton removeFromSuperview];
    [activityView startAnimating];
    
    [self.delegate moviePlayerControl:sender didPerformAction:NGMoviePlayerControlActionStartToPlay];
}

@end
