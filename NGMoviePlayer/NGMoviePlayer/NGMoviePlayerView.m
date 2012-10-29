#import "NGMoviePlayerView.h"
#import "NGVolumeControl.h"
#import "NGMoviePlayerLayerView.h"
#import "NGMoviePlayerControlView.h"
#import "NGMoviePlayerControlView+NGPrivate.h"
#import "NGMoviePlayerPlaceholderView.h"
#import "NGMoviePlayerControlActionDelegate.h"
#import "NGMoviePlayerVideoGravity.h"
#import "NGScrubber.h"


#define kNGControlVisibilityDuration        5.


static char playerLayerReadyForDisplayContext;


@interface NGMoviePlayerView () <UIGestureRecognizerDelegate> {
    BOOL _statusBarVisible;
    UIStatusBarStyle _statusBarStyle;
    BOOL _shouldHideControls;
}

@property (nonatomic, strong, readwrite) NGMoviePlayerControlView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) UIWindow *externalWindow;
@property (nonatomic, strong) UIView *externalScreenPlaceholder;
@property (nonatomic, strong) NSMutableSet *videoOverlayViews;

@property (nonatomic, readonly, getter = isAirPlayVideoActive) BOOL airPlayVideoActive;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.clipsToBounds = YES;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.backgroundColor = [UIColor clearColor];

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
    AVPlayerLayer *playerLayer = (AVPlayerLayer *)[_playerLayerView layer];

    [_placeholderView removeFromSuperview];
    [_playerLayerView removeFromSuperview];
    [playerLayer removeFromSuperlayer];
    [playerLayer removeObserver:self forKeyPath:@"readyForDisplay"];

    [_externalScreenPlaceholder removeFromSuperview];
    for (UIView *view in _videoOverlayViews) {
        [view removeFromSuperview];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIScreenDidDisconnectNotification object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutControls) object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSObject KVO
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &playerLayerReadyForDisplayContext) {
        BOOL readyForDisplay = [[change valueForKey:NSKeyValueChangeNewKey] boolValue];

        if (self.playerLayerView.layer.opacity == 0.f && readyForDisplay) {
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];

            animation.duration = kNGFadeDuration;
            animation.fromValue = [NSNumber numberWithFloat:0.];
            animation.toValue = [NSNumber numberWithFloat:1.];
            animation.removedOnCompletion = NO;

            self.playerLayerView.layer.opacity = 1.f;
            [self.playerLayerView.layer addAnimation:animation forKey:nil];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview == nil) {
        [self.playerLayer.player pause];
    }

    [super willMoveToSuperview:newSuperview];
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    if (newWindow == nil) {
        [self.playerLayer.player pause];
    }

    [super willMoveToWindow:newWindow];
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
    if (controlsVisible) {
        [self bringSubviewToFront:self.controlsView];
    } else {
        [self.controlsView.volumeControl setExpanded:NO animated:YES];
    }
    
    if (controlsVisible != _controlsVisible) {
        _controlsVisible = controlsVisible;

        NSTimeInterval duration = animated ? kNGFadeDuration : 0.;
        NGMoviePlayerControlAction willAction = controlsVisible ? NGMoviePlayerControlActionWillShowControls : NGMoviePlayerControlActionWillHideControls;
        NGMoviePlayerControlAction didAction = controlsVisible ? NGMoviePlayerControlActionDidShowControls : NGMoviePlayerControlActionDidHideControls;

        [self.delegate moviePlayerControl:self.controlsView didPerformAction:willAction];

        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOutControls) object:nil];
        // Doesn't work on device (doesn't fade but jumps from alpha 0 to 1) -> currently deactivated
        // rasterization fades out the view as a whole instead of setting alpha on each subview
        // it's similar to setting UIViewGroupOpacity, but only for this particular view
        // self.controlsView.scrubberControl.layer.shouldRasterize = YES;
        // self.controlsView.scrubberControl.layer.rasterizationScale = [UIScreen mainScreen].scale;

        [UIView animateWithDuration:duration
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.controlsView.alpha = controlsVisible ? 1.f : 0.f;
                         } completion:^(BOOL finished) {
                             [self restartFadeOutControlsViewTimer];
                             [self.delegate moviePlayerControl:self.controlsView didPerformAction:didAction];

                             //self.controlsView.scrubberControl.layer.shouldRasterize = NO;
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
        _placeholderView.frame = self.bounds;
        _placeholderView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_placeholderView];
    }
}

- (void)hidePlaceholderViewAnimated:(BOOL)animated {
    self.backgroundColor = [UIColor blackColor];

    if (animated) {
        [UIView animateWithDuration:kNGFadeDuration
                         animations:^{
                             self.placeholderView.alpha = 0.f;
                         } completion:^(BOOL finished) {
                             [self.placeholderView removeFromSuperview];
                         }];
    } else {
        [self.placeholderView removeFromSuperview];
    }
}

- (void)showPlaceholderViewAnimated:(BOOL)animated {
    if (animated) {
        self.placeholderView.alpha = 0.f;
        [self addSubview:self.placeholderView];
        [UIView animateWithDuration:kNGFadeDuration
                         animations:^{
                             self.placeholderView.alpha = 1.f;
                         }];
    } else {
        self.placeholderView.alpha = 1.f;
        [self addSubview:self.placeholderView];
    }
}

- (void)setControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle != self.controlsView.controlStyle) {
        self.controlsView.controlStyle = controlStyle;
        [self.controlsView updateButtonsWithPlaybackStatus:self.playerLayer.player.rate > 0.f];

        BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;

        // hide status bar in fullscreen, restore to previous state
        if (controlStyle == NGMoviePlayerControlStyleFullscreen) {
            [[UIApplication sharedApplication] setStatusBarStyle: (isIPad ? UIStatusBarStyleBlackOpaque : UIStatusBarStyleBlackTranslucent)];
            [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
        } else {
            [[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle];
            [[UIApplication sharedApplication] setStatusBarHidden:!_statusBarVisible withAnimation:UIStatusBarAnimationFade];
        }
    }

    self.controlsVisible = NO;
}

- (NGMoviePlayerControlStyle)controlStyle {
    return self.controlsView.controlStyle;
}

- (AVPlayerLayer *)playerLayer {
    return (AVPlayerLayer *)[self.playerLayerView layer];
}

- (NGMoviePlayerScreenState)screenState {
    if (self.externalWindow != nil) {
        return NGMoviePlayerScreenStateExternal;
    } else if (self.airPlayVideoActive) {
        return NGMoviePlayerScreenStateAirPlay;
    } else {
        return NGMoviePlayerScreenStateDevice;
    }
}

- (UIView *)externalScreenPlaceholder {
    if(_externalScreenPlaceholder == nil) {
        BOOL isIPad = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad;

        _externalScreenPlaceholder = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"NGMoviePlayer.bundle/playerBackground"]];
        _externalScreenPlaceholder.userInteractionEnabled = YES;
        _externalScreenPlaceholder.frame = self.bounds;
        _externalScreenPlaceholder.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

        UIView *externalScreenPlaceholderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, (isIPad ? 280 : 140))];

        UIImageView *externalScreenPlaceholderImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(isIPad ? @"NGMoviePlayer.bundle/wildcatNoContentVideos@2x" : @"NGMoviePlayer.bundle/wildcatNoContentVideos")]];
        externalScreenPlaceholderImageView.frame = CGRectMake((320-externalScreenPlaceholderImageView.image.size.width)/2, 0, externalScreenPlaceholderImageView.image.size.width, externalScreenPlaceholderImageView.image.size.height);
        [externalScreenPlaceholderView addSubview:externalScreenPlaceholderImageView];

        UILabel *externalScreenLabel = [[UILabel alloc] initWithFrame:CGRectMake(29, externalScreenPlaceholderImageView.frame.size.height + (isIPad ? 15 : 5), 262, 30)];
        externalScreenLabel.font = [UIFont systemFontOfSize:(isIPad ? 26.0f : 20.0f)];
        externalScreenLabel.textAlignment = UITextAlignmentCenter;
        externalScreenLabel.backgroundColor = [UIColor clearColor];
        externalScreenLabel.textColor = [UIColor darkGrayColor];
        externalScreenLabel.text = self.airPlayVideoActive ? @"AirPlay" : @"VGA";
        [externalScreenPlaceholderView addSubview:externalScreenLabel];

        UILabel *externalScreenDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, externalScreenLabel.frame.origin.y + (isIPad ? 35 : 20), 320, 30)];
        externalScreenDescriptionLabel.font = [UIFont systemFontOfSize:(isIPad ? 14.0f : 10.0f)];
        externalScreenDescriptionLabel.textAlignment = UITextAlignmentCenter;
        externalScreenDescriptionLabel.backgroundColor = [UIColor clearColor];
        externalScreenDescriptionLabel.textColor = [UIColor lightGrayColor];
        externalScreenDescriptionLabel.text = [NSString stringWithFormat:@"Dieses Video wird über %@ wiedergegeben.", externalScreenLabel.text];
        [externalScreenPlaceholderView addSubview:externalScreenDescriptionLabel];

        externalScreenPlaceholderView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        externalScreenPlaceholderView.center = _externalScreenPlaceholder.center;

        [_externalScreenPlaceholder addSubview:externalScreenPlaceholderView];
    }

    return _externalScreenPlaceholder;
}

- (CGFloat)topControlsViewHeight {
    return CGRectGetMaxY(self.controlsView.topControlsView.frame);
}

- (CGFloat)bottomControlsViewHeight {
    CGFloat height = CGRectGetHeight(self.controlsView.frame);

    return  height - CGRectGetMinY(self.controlsView.bottomControlsView.frame) + 2*(height - CGRectGetMaxY(self.controlsView.bottomControlsView.frame));
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerView UI Update
////////////////////////////////////////////////////////////////////////

- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration {
    if (!isnan(currentTime) && !isnan(duration)) {
        [self.controlsView updateScrubberWithCurrentTime:currentTime duration:duration];
    }
}

- (void)updateWithPlaybackStatus:(BOOL)isPlaying {
    [self.controlsView updateButtonsWithPlaybackStatus:isPlaying];

    _shouldHideControls = isPlaying;
}

- (void)addVideoOverlayView:(UIView *)overlayView {
    if (overlayView != nil) {
        if (_videoOverlayViews == nil) {
            _videoOverlayViews = [NSMutableSet set];
        }

        UIView *superview = self.playerLayerView.superview;

        [superview insertSubview:overlayView aboveSubview:self.playerLayerView];
        [self.videoOverlayViews addObject:overlayView];
    }
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
#pragma mark - External Screen (VGA)
////////////////////////////////////////////////////////////////////////

- (void)setupExternalWindowForScreen:(UIScreen *)screen {
    if (screen != nil) {
        self.externalWindow = [[UIWindow alloc] initWithFrame:screen.applicationFrame];
        self.externalWindow.hidden = NO;
        self.externalWindow.clipsToBounds = YES;

        if (screen.availableModes.count > 0) {
            UIScreenMode *desiredMode = [screen.availableModes objectAtIndex:screen.availableModes.count-1];
            screen.currentMode = desiredMode;
        }

        self.externalWindow.screen = screen;
        [self.externalWindow makeKeyAndVisible];
    } else {
        [self.externalWindow removeFromSuperview];
        [self.externalWindow resignKeyWindow];
        self.externalWindow.hidden = YES;
        self.externalWindow = nil;
    }
}

- (void)updateViewsForCurrentScreenState {
    [self positionViewsForState:self.screenState];

    [self setControlsVisible:NO];

    int64_t delayInSeconds = 1.;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self setControlsVisible:YES animated:YES];
    });
}

- (void)positionViewsForState:(NGMoviePlayerScreenState)screenState {
    UIView *viewBeneathOverlayViews = self.playerLayerView;

    switch (screenState) {
        case NGMoviePlayerScreenStateExternal:
        case NGMoviePlayerScreenStateAirPlay: {
            self.playerLayerView.frame = self.externalWindow.bounds;
            [self.externalWindow addSubview:self.playerLayerView];
            [self insertSubview:self.externalScreenPlaceholder belowSubview:self.placeholderView];
            viewBeneathOverlayViews = self.externalScreenPlaceholder;
            break;
        }

        case NGMoviePlayerScreenStateDevice:
        default: {
            self.playerLayerView.frame = self.bounds;
            [self insertSubview:self.playerLayerView belowSubview:self.placeholderView];
            [self.externalScreenPlaceholder removeFromSuperview];
            self.externalScreenPlaceholder = nil;
            break;
        }
    }

    UIView *superview = self.playerLayerView.superview;
    
    for (UIView *overlayView in self.videoOverlayViews) {
        // we assume this means "stick to bottom"
        if (overlayView.autoresizingMask & UIViewAutoresizingFlexibleTopMargin) {
            overlayView.frame = CGRectMake(0.f, superview.frame.size.height - overlayView.frame.size.height,superview.bounds.size.width, overlayView.frame.size.height);
        }

        // we assume this means "stick to top"
        else if (overlayView.autoresizingMask & UIViewAutoresizingFlexibleBottomMargin) {
            overlayView.frame = CGRectMake(0.f, overlayView.frame.origin.y, superview.bounds.size.width, overlayView.frame.size.height);
        }

        // we assume this means fullscreen-overlay
        else if (overlayView.autoresizingMask & (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)) {
            overlayView.frame = (CGRect){CGPointZero, superview.frame.size};
        }

        [superview insertSubview:overlayView aboveSubview:viewBeneathOverlayViews];
    }

    [self bringSubviewToFront:self.controlsView];
}

- (void)externalScreenDidConnect:(NSNotification *)notification {
    UIScreen *screen = [notification object];

    [self setupExternalWindowForScreen:screen];
    [self positionViewsForState:self.screenState];
}

- (void)externalScreenDidDisconnect:(NSNotification *)notification {
    [self setupExternalWindowForScreen:nil];
    [self positionViewsForState:self.screenState];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIGestureRecognizerDelegate
////////////////////////////////////////////////////////////////////////

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (self.controlsVisible || self.placeholderView.alpha > 0.f) {
        id playButton = nil;

        if (self.controlsView.volumeControl.expanded) {
            return NO;
        }
        
        if ([self.placeholderView respondsToSelector:@selector(playButton)]) {
            playButton = [self.placeholderView performSelector:@selector(playButton)];
        }

        // We here rely on the fact that nil terminates a list, because playButton can be nil
        // ATTENTION: DO NOT CONVERT THIS TO MODERN OBJC-SYNTAX @[]
        NSArray *controls = [NSArray arrayWithObjects:self.controlsView.topControlsView, self.controlsView.bottomControlsView, playButton, nil];

        // We dont want to to hide the controls when we tap em
        for (UIView *view in controls) {
            if ([view pointInside:[touch locationInView:view] withEvent:nil]) {
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
    _statusBarStyle = [UIApplication sharedApplication].statusBarStyle;

    // Player Layer
    _playerLayerView = [[NGMoviePlayerLayerView alloc] initWithFrame:self.bounds];
    _playerLayerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _playerLayerView.alpha = 0.f;

    [self.playerLayer addObserver:self
                       forKeyPath:@"readyForDisplay"
                          options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                          context:&playerLayerReadyForDisplayContext];

    // Controls
    _controlsView = [[NGMoviePlayerControlView alloc] initWithFrame:self.bounds];
    _controlsView.alpha = 0.f;
    [self addSubview:_controlsView];

    [_controlsView.volumeControl addTarget:self action:@selector(volumeControlValueChanged:) forControlEvents:UIControlEventValueChanged];

    // Placeholder
    NGMoviePlayerPlaceholderView *placeholderView = [[NGMoviePlayerPlaceholderView alloc] initWithFrame:self.bounds];
    [placeholderView addPlayButtonTarget:self action:@selector(handlePlayButtonPress:)];
    _placeholderView = placeholderView;
    [self addSubview:_placeholderView];

    // Gesture Recognizer for self
    UITapGestureRecognizer *doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:doubleTapGestureRecognizer];

    UITapGestureRecognizer *singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    singleTapGestureRecognizer.delegate = self;
    [self addGestureRecognizer:singleTapGestureRecognizer];

    // Gesture Recognizer for controlsView
    doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    doubleTapGestureRecognizer.delegate = self;
    [self.controlsView addGestureRecognizer:doubleTapGestureRecognizer];

    singleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    [singleTapGestureRecognizer requireGestureRecognizerToFail:doubleTapGestureRecognizer];
    singleTapGestureRecognizer.delegate = self;
    [self.controlsView addGestureRecognizer:singleTapGestureRecognizer];

    // Check for external screen
    if ([UIScreen screens].count > 1) {
        for (UIScreen *screen in [UIScreen screens]) {
            if (screen != [UIScreen mainScreen]) {
                [self setupExternalWindowForScreen:screen];
                break;
            }
        }

        NSAssert(self.externalWindow != nil, @"External screen counldn't be determined, no window was created");
    }

    [self positionViewsForState:self.screenState];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidConnect:) name:UIScreenDidConnectNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(externalScreenDidDisconnect:) name:UIScreenDidDisconnectNotification object:nil];
}

- (void)fadeOutControls {
    if (_shouldHideControls && self.screenState == NGMoviePlayerScreenStateDevice) {
        [self setControlsVisible:NO animated:YES];
    }
}

- (BOOL)isAirPlayVideoActive {
    if ([AVPlayer instancesRespondToSelector:@selector(isAirPlayVideoActive)]) {
        return self.playerLayer.player.airPlayVideoActive;
    }

    return NO;
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

- (void)handlePlayButtonPress:(id)playControl {
    [self.delegate moviePlayerControl:playControl didPerformAction:NGMoviePlayerControlActionStartToPlay];
}

- (void)volumeControlValueChanged:(id)sender {
    [self restartFadeOutControlsViewTimer];
}

@end
