#import <MediaPlayer/MediaPlayer.h>

#import "NGVolumeControl.h"
#import "NGGeometryFunctions.h"
#import "NGVolumeControl+NGCustomize.h"
#import "NGVolumeSlider.h"


#define NGSystemVolumeDidChangeNotification         @"AVSystemController_SystemVolumeDidChangeNotification"
#define kNGSliderWidth                              48.f
#define kNGSliderHeight                            170.f
#define kNGMinimumSlideDistance                     10.f
#define kNGShadowRadius                             10.f
#define kNGSlideDuration                             0.2
#define kNGMinimumTapSize                           44.f


static MPVolumeView *ng_volumeView = nil;


@interface NGVolumeControl ()

@property (nonatomic, strong) UIImageView *volumeImageView;
@property (nonatomic, strong) UIView *sliderView;
@property (nonatomic, strong) NGVolumeSlider *slider;
@property (nonatomic, assign) float systemVolume;
@property (nonatomic, assign) float currentSystemVolume;
@property (nonatomic, readonly) BOOL sliderVisible;

@property (nonatomic, assign) CGPoint touchStartPoint;
@property (nonatomic, assign) BOOL touchesMoved;

@property (nonatomic, strong) UIImageView *sliderBackgroundView;

@end


@implementation NGVolumeControl

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.opaque = NO;
        self.backgroundColor = [UIColor clearColor];

        _sliderHeight = kNGSliderHeight;
        _expandDirection = NGVolumeControlExpandDirectionUp;
        _expanded = NO;
        _minimumTrackColor = [UIColor whiteColor];
        _maximumTrackColor = [UIColor colorWithWhite:1.f alpha:.2f];

        _touchesMoved = NO;
        _touchStartPoint = CGPointZero;

        _volumeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 21.f, 23.f)];
        _volumeImageView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
        _volumeImageView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _volumeImageView.contentMode = UIViewContentModeCenter;
        [self addSubview:_volumeImageView];

        _sliderView = [[UIView alloc] initWithFrame:[self volumeViewFrameForExpandDirection:_expandDirection]];
        _sliderView.backgroundColor = [UIColor clearColor];
        _sliderView.contentMode = UIViewContentModeTop;
        _sliderView.clipsToBounds = YES;
        _sliderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSliderViewPan:)];
        panGesture.cancelsTouchesInView = YES;
        panGesture.delaysTouchesBegan = YES;
        panGesture.delaysTouchesEnded = YES;
        [_sliderView addGestureRecognizer:panGesture];

        _sliderBackgroundView = [[UIImageView alloc] initWithFrame:CGRectInset(_sliderView.bounds, 10.f, 0.f)];
        _sliderBackgroundView.image = [self imageForSliderBackgroundForExpandDirection:_expandDirection];
        _sliderBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_sliderView addSubview:_sliderBackgroundView];
        [self hideSliderAnimated:NO];
        [self addSubview:_sliderView];

        _slider = [[NGVolumeSlider alloc] initWithFrame:CGRectMake(0.f, 0.f, _sliderHeight - 30.f, kNGSliderWidth)];
        _slider.minimumValue = 0.f;
        _slider.maximumValue = 1.f;
        _slider.transform = [self transformForExpandDirection:_expandDirection];
        _slider.center = CGPointMake(_sliderView.frame.size.width/2.f, _sliderView.frame.size.height/2.f - 5.f);
        _slider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
        [_slider addTarget:self action:@selector(handleSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self customizeSlider:_slider];
        [self setSliderHeight:_sliderHeight];
        [_sliderView addSubview:_slider];

        // set properties of glow Layer
        CALayer *glowLayer = self.layer;
        if ([glowLayer respondsToSelector:@selector(setShadowPath:)] && [glowLayer respondsToSelector:@selector(shadowPath)]) {
            CGMutablePathRef path = CGPathCreateMutable();

            CGPathAddRect(path, NULL, glowLayer.bounds);
            glowLayer.shadowPath = path;
            glowLayer.shadowOffset = CGSizeZero;
            glowLayer.shadowColor = [UIColor whiteColor].CGColor;
            glowLayer.shadowRadius = kNGShadowRadius;

            CGPathRelease(path);
        }
        
        self.currentSystemVolume = self.systemVolume;

        // observe changes to system volume (volume buttons)
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(systemVolumeChanged:)
                                                     name:NGSystemVolumeDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    _volumeDelegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NGSystemVolumeDidChangeNotification object:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Class Methods
////////////////////////////////////////////////////////////////////////

+ (void)beginPreventingSystemVolumePopup {
    if (ng_volumeView == nil) {
        // Prevent Audio-Change Popus
        ng_volumeView = [[MPVolumeView alloc] initWithFrame:CGRectMake(-2000., -2000., 0.f, 0.f)];
        ng_volumeView.alpha = 0.1f;
        ng_volumeView.userInteractionEnabled = NO;
    }

    if (ng_volumeView.superview == nil) {
        NSArray *windows = [UIApplication sharedApplication].windows;

        if (windows.count > 0) {
            [[windows objectAtIndex:0] addSubview:ng_volumeView];
        }
    }
}

+ (void)endPreventingSystemVolumePopup {
    [ng_volumeView removeFromSuperview];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)willMoveToSuperview:(UIView *)newSuperview {
    // if we move to a superview we update the UI
    if (newSuperview != nil) {
        [self updateUI];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    // if we move to a window we update the UI
    if (newWindow != nil) {
        [self updateUI];
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect rectToTest = self.bounds;

    // if the real bounds are a too small hit-target increase the artificial hit-bounds rect
    if (self.bounds.size.width < kNGMinimumTapSize && self.bounds.size.height < kNGMinimumTapSize) {
        rectToTest = CGRectInset(self.bounds,
                                 (self.bounds.size.width - kNGMinimumTapSize)/2.f,
                                 (self.bounds.size.height - kNGMinimumTapSize)/2.f);
    }

    // if the slider is expanded we also have to take the sliderView into account
    BOOL inside = (CGRectContainsPoint(rectToTest, point) ||
                   (self.sliderVisible && CGRectContainsPoint(self.sliderView.frame, point)));

    if (!inside) {
        [self setExpanded:NO animated:YES];
    }

    return inside;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIControl
////////////////////////////////////////////////////////////////////////

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [self handleTouchesBeganAtPoint:[touch locationInView:self]];

    if (!self.expanded) {
        [self setExpanded:YES animated:YES];
        self.touchesMoved = NO;
        self.slider.userInteractionEnabled = NO;
    } else {
        [self setExpanded:NO animated:YES];
    }

    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.expanded) {
        CGPoint point = [touch locationInView:self.sliderView];

        [self handleTouchesMovedToPoint:point];
    }

    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    // was it a quick-move gesture -> collapse again
    if (self.touchesMoved) {
        [self setExpanded:NO animated:YES];
        self.touchesMoved = NO;
    }

    self.slider.userInteractionEnabled = YES;
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    self.slider.userInteractionEnabled = YES;
    self.touchesMoved = NO;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    // show glow of control like UIButton (showsTouchWhenHighlighted)
    CALayer *glowLayer = self.layer;

    if ([glowLayer respondsToSelector:@selector(setShadowPath:)] && [glowLayer respondsToSelector:@selector(shadowPath)]) {
        if (highlighted || self.touchesMoved) {
            glowLayer.shadowOpacity = 0.9f;
        } else {
            glowLayer.shadowOpacity = 0.f;
        }
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGVolumeControl
////////////////////////////////////////////////////////////////////////

- (void)setVolume:(float)volume {
    float maxBound = MIN(volume, 1.f);
    float boundedVolume = MAX(maxBound, 0.f);

    // update the system volume
    self.systemVolume = boundedVolume;

    // system volume doesn't work on the simulator, so for testing purposes we
    // set the slider/image directly instead of using system volume as in updateUI
#if TARGET_IPHONE_SIMULATOR
    self.volumeImageView.image = [self imageForVolume:volume];
    self.slider.value = volume;
#else
    [self updateUI];
#endif

    [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (float)volume {
    return self.systemVolume;
}

- (void)setExpanded:(BOOL)expanded {
    [self setExpanded:expanded animated:NO];
}

- (void)setExpanded:(BOOL)expanded animated:(BOOL)animated {
    if (expanded != _expanded) {
        _expanded = expanded;

        if (expanded) {
            [[self class] beginPreventingSystemVolumePopup];
            [self showSliderAnimated:animated];
        } else {
            [[self class] endPreventingSystemVolumePopup];
            [self hideSliderAnimated:animated];
        }
    }
}

- (void)setExpandDirection:(NGVolumeControlExpandDirection)expandDirection {
    if (expandDirection != _expandDirection) {
        _expandDirection = expandDirection;

        self.slider.transform = [self transformForExpandDirection:expandDirection];
        self.sliderView.frame = [self volumeViewFrameForExpandDirection:expandDirection];

        self.sliderBackgroundView.image = [self imageForSliderBackgroundForExpandDirection:expandDirection];
    }
}

- (void)setMinimumTrackColor:(UIColor *)minimumTrackColor {
    if (minimumTrackColor != _minimumTrackColor) {
        _minimumTrackColor = minimumTrackColor;

        [self customizeSlider:self.slider];
    }
}

- (void)setMaximumTrackColor:(UIColor *)maximumTrackColor {
    if (maximumTrackColor != _maximumTrackColor) {
        _maximumTrackColor = maximumTrackColor;

        [self customizeSlider:self.slider];
    }
}

- (void)setSliderHeight:(CGFloat)sliderHeight {
    if (sliderHeight != _sliderHeight) {
        _sliderHeight = sliderHeight;
    }

    CGFloat offset = _expandDirection == NGVolumeControlExpandDirectionDown ? -5.f : 5.f;
    CGFloat horizontalOffset = _expandDirection == NGVolumeControlExpandDirectionDown ? 0.5f : 0.f;

    // Update UI to new height
    [self hideSliderAnimated:NO];
    self.sliderView.frame = [self volumeViewFrameForExpandDirection:self.expandDirection];

    self.slider.transform = CGAffineTransformIdentity;
    self.slider.frame = (CGRect){CGPointZero, (CGSize){_sliderHeight - 30.f, kNGSliderWidth}};
    self.slider.transform = [self transformForExpandDirection:self.expandDirection];
    self.slider.center = CGPointMake(self.sliderView.frame.size.width/2.f + horizontalOffset, self.sliderView.frame.size.height/2.f - offset);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGVolumeControl+NGSubclass
////////////////////////////////////////////////////////////////////////

- (UIImage *)imageForVolume:(float)volume {
    // Returns an image that represents the current volume
    if (volume < 0.001f) {
        return [UIImage imageNamed:@"NGVolumeControl.bundle/Volume0"];
    } else if (volume < 0.33f) {
        return [UIImage imageNamed:@"NGVolumeControl.bundle/Volume1"];
    } else if (volume < 0.66f) {
        return [UIImage imageNamed:@"NGVolumeControl.bundle/Volume2"];
    } else {
        return [UIImage imageNamed:@"NGVolumeControl.bundle/Volume3"];
    }
}

- (void)customizeSlider:(UISlider *)slider {
    if ([slider respondsToSelector:@selector(setMinimumTrackTintColor:)]) {
        slider.minimumTrackTintColor = self.minimumTrackColor;
        slider.maximumTrackTintColor = self.maximumTrackColor;
    } else {
        //Build a rect of appropriate size at origin 0,0
        CGRect fillRect = CGRectMake(0.f,0.f,1.f,10.f);

        //Create a context of the appropriate size
        UIGraphicsBeginImageContext(CGSizeMake(1.f, 10.f));
        CGContextRef currentContext = UIGraphicsGetCurrentContext();
        //Set the fill color
        CGContextSetFillColorWithColor(currentContext, self.minimumTrackColor.CGColor);
        //Fill the color
        CGContextFillRect(currentContext, fillRect);
        //Snap the picture and close the context
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.slider setMinimumTrackImage:image forState:UIControlStateNormal];

        //Create a context of the appropriate size
        UIGraphicsBeginImageContext(CGSizeMake(1.f, 10.f));
        currentContext = UIGraphicsGetCurrentContext();
        //Set the fill color
        CGContextSetFillColorWithColor(currentContext, self.maximumTrackColor.CGColor);
        //Fill the color
        CGContextFillRect(currentContext, fillRect);
        //Snap the picture and close the context
        image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [self.slider setMaximumTrackImage:image forState:UIControlStateNormal];
    }

    [self.slider setThumbImage:[UIImage imageNamed:@"NGVolumeControl.bundle/ScrubberKnob"] forState:UIControlStateNormal];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)setSystemVolume:(float)systemVolume {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    
    if ([self.volumeDelegate respondsToSelector:@selector(volumeControl:didChangeOldVolume:toNewVolume:)]) {
        [self.volumeDelegate volumeControl:self didChangeOldVolume:musicPlayer.volume toNewVolume:systemVolume];
    }
    
    musicPlayer.volume = systemVolume;
    self.currentSystemVolume = systemVolume;

    // TODO: Replace with new version below
//    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
//    UISlider *volumeViewSlider = nil;
//
//    for (UIView *view in volumeView.subviews) {
//        if ([view isKindOfClass:[UISlider class]]) {
//            volumeViewSlider = (UISlider *)view;
//            break;
//        }
//    }
//
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        if ([self.volumeDelegate respondsToSelector:@selector(volumeControl:didChangeOldVolume:toNewVolume:)]) {
//            [self.volumeDelegate volumeControl:self didChangeOldVolume:volumeViewSlider.value toNewVolume:systemVolume];
//        }
//
//        volumeViewSlider.value = systemVolume;
//    });
//
//    self.currentSystemVolume = systemVolume;
}

- (float)systemVolume {
    MPMusicPlayerController *musicPlayer = [MPMusicPlayerController systemMusicPlayer];
    return musicPlayer.volume;

    // TODO: Replace with new version below
//    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
//    UISlider *volumeViewSlider = nil;
//
//    for (UIView *view in volumeView.subviews) {
//        if ([view isKindOfClass:[UISlider class]]) {
//            volumeViewSlider = (UISlider *)view;
//            break;
//        }
//    }
//
//    return volumeViewSlider.value;
}

- (CGAffineTransform)transformForExpandDirection:(NGVolumeControlExpandDirection)expandDirection {
    if (expandDirection == NGVolumeControlExpandDirectionUp) {
        return CGAffineTransformMakeRotation(-M_PI/2.f);
    } else {
        return CGAffineTransformMakeRotation(M_PI/2.f);
    }
}

- (CGRect)volumeViewFrameForExpandDirection:(NGVolumeControlExpandDirection)expandDirection {
    CGRect frame = CGRectZero;

    if (expandDirection == NGVolumeControlExpandDirectionUp) {
        frame = CGRectMake(0.f, -self.sliderHeight, self.bounds.size.width, self.sliderHeight);
    } else {
        frame = CGRectMake(0.f, self.bounds.size.height, self.bounds.size.width, self.sliderHeight);
    }

    return CGRectInset(frame,-10.f,0.f);
}

- (UIImage *)imageForSliderBackgroundForExpandDirection:(NGVolumeControlExpandDirection)expandDirection {
    UIImage *sliderBackgroundImage = [UIImage imageNamed:@"NGVolumeControl.bundle/volume-background"];

    // mirror image if slider expands downwards
    if (expandDirection == NGVolumeControlExpandDirectionDown) {
        sliderBackgroundImage = [[UIImage alloc] initWithCGImage:sliderBackgroundImage.CGImage
                                                           scale:[UIScreen mainScreen].scale
                                                     orientation:UIImageOrientationDown];
    }

    if ([sliderBackgroundImage respondsToSelector:@selector(resizableImageWithCapInsets:)]) {
        sliderBackgroundImage = [sliderBackgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(47.f, 24.f, 47.f, 24.f)];
    } else {
        sliderBackgroundImage = [sliderBackgroundImage stretchableImageWithLeftCapWidth:24 topCapHeight:47];
    }

    return sliderBackgroundImage;
}

- (BOOL)sliderVisible {
    return self.sliderView.alpha > 0.f && !self.sliderView.hidden;
}

- (void)toggleSliderAnimated:(BOOL)animated {
    if (self.sliderVisible) {
        [self hideSliderAnimated:animated];
    } else {
        [self showSliderAnimated:animated];
    }
}

- (void)showSliderAnimated:(BOOL)animated {
    if (self.sliderVisible) {
        return;
    }

    if ([self.volumeDelegate respondsToSelector:@selector(volumeControlWillExpand:)]) {
        [self.volumeDelegate volumeControlWillExpand:self];
    }

    if (animated) {
        CGRect frame = self.sliderView.frame;

        frame.size.height = 0.f;

        if (self.expandDirection == NGVolumeControlExpandDirectionUp) {
            frame.origin.y = 0.f;
        } else {
            frame.origin.y = self.bounds.size.height;
        }

        self.sliderView.frame = frame;
        self.sliderView.alpha = 0.f;

        frame.size.height = self.sliderHeight;

        if (self.expandDirection == NGVolumeControlExpandDirectionUp) {
            frame.origin.y = -self.sliderHeight;
        }

        [UIView animateWithDuration:kNGSlideDuration
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.sliderView.frame = frame;
                             self.sliderView.alpha = 1.f;
                         } completion:^(BOOL finished) {
                             if ([self.volumeDelegate respondsToSelector:@selector(volumeControlDidExpand:)]) {
                                 [self.volumeDelegate volumeControlDidExpand:self];
                             }
                         }];
    } else {
        self.sliderView.alpha = 1.f;
        if ([self.volumeDelegate respondsToSelector:@selector(volumeControlDidExpand:)]) {
            [self.volumeDelegate volumeControlDidExpand:self];
        }
    }
}

- (void)hideSliderAnimated:(BOOL)animated {
    if (!self.sliderVisible) {
        return;
    }

    if ([self.volumeDelegate respondsToSelector:@selector(volumeControlWillShrink:)]) {
        [self.volumeDelegate volumeControlWillShrink:self];
    }

    if (animated) {
        CGRect frame = self.sliderView.frame;

        self.sliderView.alpha = 1.f;

        frame.size.height = 0.f;

        if (self.expandDirection == NGVolumeControlExpandDirectionUp) {
            frame.origin.y = 0.f;
        } else {
            frame.origin.y = self.bounds.size.height;
        }

        [UIView animateWithDuration:kNGSlideDuration
                              delay:0.
                            options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                             self.sliderView.frame = frame;
                             self.sliderView.alpha = 0.f;
                         } completion:^(BOOL finished) {
                             if ([self.volumeDelegate respondsToSelector:@selector(volumeControlDidShrink:)]) {
                                 [self.volumeDelegate volumeControlDidShrink:self];
                             }
                         }];
    } else {
        self.sliderView.alpha = 0.f;
        if ([self.volumeDelegate respondsToSelector:@selector(volumeControlDidShrink:)]) {
            [self.volumeDelegate volumeControlDidShrink:self];
        }
    }
}

- (void)updateUI {
    // update the UI to reflect the current volume
    self.volumeImageView.image = [self imageForVolume:self.volume];
    self.slider.value = self.volume;
}

- (void)systemVolumeChanged:(NSNotification *)notification {
    // we update the UI when the system volume changed (volume buttons)
    if ([self.volumeDelegate respondsToSelector:@selector(volumeControl:didChangeOldVolume:toNewVolume:)]) {
        float newVolume = [notification.userInfo[@"AVSystemController_AudioVolumeNotificationParameter"] floatValue];
        [self.volumeDelegate volumeControl:self didChangeOldVolume:self.currentSystemVolume toNewVolume:newVolume];
        self.currentSystemVolume = newVolume;
    }
    [self updateUI];
}

- (void)handleSliderValueChanged:(id)sender {
    self.volume = self.slider.value;
}

- (void)handleSliderViewPan:(UIPanGestureRecognizer *)panGesture {
    if (panGesture.state == UIGestureRecognizerStateBegan) {
        [self handleTouchesBeganAtPoint:[panGesture locationInView:self.sliderView]];
    }

    else if (panGesture.state == UIGestureRecognizerStateChanged) {
        CGPoint point = [panGesture locationInView:self.sliderView];

        [self handleTouchesMovedToPoint:point];
    }
}

- (void)handleTouchesBeganAtPoint:(CGPoint)point {
    self.touchStartPoint = point;
}

- (void)handleTouchesMovedToPoint:(CGPoint)point {
    CGFloat distance = NGDistanceBetweenCGPoints(point, self.touchStartPoint);

    // check if we moved the touches because we automatically collapse when the touches
    // end when the user moved the touches
    if (distance > kNGMinimumSlideDistance) {
        self.touchesMoved = YES;
    }

    if (point.y > self.sliderHeight) {
        point.y = self.sliderHeight;
    }

    CGFloat percentage = point.y/self.sliderHeight;

    if (self.expandDirection == NGVolumeControlExpandDirectionUp) {
        percentage = 1.f - percentage;
    }

    self.slider.value = percentage;
    self.volume = percentage;
}

@end
