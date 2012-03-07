#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"
#import "NGSlider.h"


#define kNGFadeDuration     0.4


@interface NGMoviePlayerView () {
    BOOL _statusBarVisible;
}

@property (nonatomic, strong, readwrite) UIView *controlsView;  // re-defined as read/write
@property (nonatomic, strong) UIView *topControlsView;
@property (nonatomic, strong) UIView *bottomControlsView;
@property (nonatomic, strong) NGMoviePlayerLayerView *playerLayerView;
@property (nonatomic, strong) NGSlider *scrubber;
@property (nonatomic, strong) UIButton *playPauseButton;
@property (nonatomic, strong) UILabel *currentTimeLabel;
@property (nonatomic, strong) UILabel *remainingTimeLabel;


- (void)setupScrubber:(NGSlider *)scrubber fullScreen:(BOOL)fullScreen;

// methods to update the UI to reflect current state
- (void)updateScrubberWithCurrentTime:(NSInteger)currentTime duration:(NSInteger)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

@end


@implementation NGMoviePlayerView

@dynamic playerLayer;

@synthesize controlsView = _controlsView;
@synthesize topControlsView = _topControlsView;
@synthesize bottomControlsView = _bottomControlsView;
@synthesize controlsVisible = _controlsVisible;
@synthesize fullscreen = _fullscreen;
@synthesize playerLayerView = _playerLayerView;
@synthesize scrubber = _scrubber;
@synthesize playPauseButton = _playPauseButton;
@synthesize currentTimeLabel = _currentTimeLabel;
@synthesize remainingTimeLabel = _remainingTimeLabel;
@synthesize scrubberFillColor = _scrubberFillColor;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        _scrubberFillColor = [UIColor purpleColor];
        _controlsVisible = NO;
        _fullscreen = NO;
        _statusBarVisible = ![UIApplication sharedApplication].statusBarHidden;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

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

- (void)setupScrubber:(NGSlider *)scrubber fullScreen:(BOOL)fullScreen {
    scrubber.alpha = 0.75f;
    
    if (fullScreen) {
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
