#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"
#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerVideoGravity.h"

#define kNGFadeDuration                     0.4
#define kNGControlVisibilityDuration        4.


static char playerLayerReadyForDisplayContext;


@interface NGMoviePlayerView () <UIGestureRecognizerDelegate> {
    BOOL _statusBarVisible;
    BOOL _readyForDisplayTriggered;
}

@property (nonatomic, strong, readwrite) NGMoviePlayerControlView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) UIView *placeholderView;
@property (nonatomic, strong) UIWindow *externalWindow;

@property (nonatomic, strong) UITapGestureRecognizer *singleTapGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGestureRecognizer;

- (void)setup;
- (void)fadeOutControls;

- (void)handleSingleTap:(UITapGestureRecognizer *)tap;
- (void)handleDoubleTap:(UITapGestureRecognizer *)tap;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

@synthesize controlsView = _controlsView;
@synthesize controlsVisible = _controlsVisible;
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
            
            [self setControlsVisible:YES animated:YES];
            // fade out placeholderView
            [UIView animateWithDuration:1.
                             animations:^{
                                 self.placeholderView.alpha = 0.f;
                             } completion:^(BOOL finished) {
                                 [self.placeholderView removeFromSuperview];
                                 self.placeholderView = nil;
                             }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

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
    if (self.controlsVisible) {
        NSArray *controls = [NSArray arrayWithObjects:self.controlsView.topControlsView, self.controlsView.bottomControlsView, nil];
        
        // We dont want to to hide the controls when we tap em
        for (UIView *view in controls) {
            if (CGRectContainsPoint(view.frame, [touch locationInView:self])) {
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
    
    // Placeholder
    _placeholderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/playerBackground"]];
    _placeholderView.frame = self.bounds;
    _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:_placeholderView];
    
    // Controls
    _controlsView = [[NGMoviePlayerControlView alloc] initWithFrame:self.bounds];
    [self addSubview:_controlsView];
    
    // Player Layer
    _playerLayerView = [[NGMoviePlayerLayerView alloc] initWithFrame:self.bounds];
    _playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_playerLayerView];
    
    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&playerLayerReadyForDisplayContext];
    
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
    [self setControlsVisible:NO animated:YES];
}

- (void)handleSingleTap:(UITapGestureRecognizer *)tap {
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        // Toggle control visibility on single tap
        [self setControlsVisible:!self.controlsVisible animated:YES];
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)tap {
    if ((tap.state & UIGestureRecognizerStateRecognized) == UIGestureRecognizerStateRecognized) {
        // Toggle video gravity on double tap
        self.playerLayer.videoGravity = NGAVLayerVideoGravityNext(self.playerLayer.videoGravity);
        // BUG: otherwise the video gravity doesn't change immediately
        self.playerLayer.bounds = self.playerLayer.bounds;
    }
}

@end
