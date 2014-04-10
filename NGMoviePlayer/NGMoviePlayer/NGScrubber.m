#import "NGScrubber.h"
#import "NGMoviePlayerFunctions.h"

////////////////////////////////////////////////////////////////////////
#pragma mark - Private UIView rendering the popup showing slider value
////////////////////////////////////////////////////////////////////////

@interface NGSliderValuePopupView : UIView  

@property (nonatomic) NSTimeInterval time;
@property (nonatomic, retain) UIFont *font;
@property (nonatomic, retain) NSString *text;

@end

@implementation NGSliderValuePopupView

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.font = [UIFont boldSystemFontOfSize:15];
    }
    
    return self;
}

- (void)drawRect:(CGRect)rect {
    // Set the fill color
	[[UIColor colorWithWhite:0.2f alpha:0.8f] setFill];
    
    // Create the path for the rounded rectangle
    CGRect roundedRect = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, self.bounds.size.width, floorf(self.bounds.size.height * 0.8));
    UIBezierPath *roundedRectPath = [UIBezierPath bezierPathWithRoundedRect:roundedRect cornerRadius:6.0];
    
    // Create the arrow path
    UIBezierPath *arrowPath = [UIBezierPath bezierPath];
    CGFloat midX = CGRectGetMidX(self.bounds);
    CGPoint p0 = CGPointMake(midX, CGRectGetMaxY(self.bounds));
    [arrowPath moveToPoint:p0];
    [arrowPath addLineToPoint:CGPointMake((midX - 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath addLineToPoint:CGPointMake((midX + 10.0), CGRectGetMaxY(roundedRect))];
    [arrowPath closePath];
    
    // Attach the arrow path to the rounded rect
    [roundedRectPath appendPath:arrowPath];
    [roundedRectPath fill];
    
    // Draw the text
    if (self.text) {
        [[UIColor colorWithWhite:1.f alpha:0.8f] set];
        CGSize s = [_text sizeWithFont:self.font];
        CGFloat yOffset = (roundedRect.size.height - s.height) / 2;
        CGRect textRect = CGRectMake(roundedRect.origin.x, yOffset, roundedRect.size.width, s.height);
        
        [_text drawInRect:textRect 
                 withFont:self.font 
            lineBreakMode:NSLineBreakByWordWrapping
                alignment:NSTextAlignmentCenter];
    }
}

- (void)setTime:(NSTimeInterval)time {
    if (_time != time) {
        _time = time;
        self.text = NGMoviePlayerGetTimeFormatted(time);
        
        [self setNeedsDisplay];
    }
}

@end


////////////////////////////////////////////////////////////////////////
#pragma mark - Private Class Extension
////////////////////////////////////////////////////////////////////////

@interface NGScrubber () {
    CGPoint _beganTrackingLocation;
    float _realPositionValue;
    NGSliderValuePopupView *valuePopupView; 
}

@property (atomic, assign, readwrite) float scrubbingSpeed;
@property (atomic, assign) CGPoint beganTrackingLocation;
@property (nonatomic, strong) UIView *playableView;

@end


@implementation NGScrubber

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.scrubbingSpeeds = [self defaultScrubbingSpeeds];
        self.scrubbingSpeedChangePositions = [self defaultScrubbingSpeedChangePositions];
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
        
        _playableValueColor = [UIColor colorWithWhite:1.f alpha:0.7f];
        _showPopupDuringScrubbing = YES;
        
        _playableView = [[UIView alloc] initWithFrame:CGRectZero];
        _playableView.userInteractionEnabled = NO;
        _playableView.backgroundColor = _playableValueColor;
        [self addSubview:_playableView];
        
        [self constructSlider];
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder *)decoder {
    if ((self = [super initWithCoder:decoder])) {
    	if ([decoder containsValueForKey:@"scrubbingSpeeds"]) {
            self.scrubbingSpeeds = [decoder decodeObjectForKey:@"scrubbingSpeeds"];
        } else {
            self.scrubbingSpeeds = [self defaultScrubbingSpeeds];
        }
        
        if ([decoder containsValueForKey:@"scrubbingSpeedChangePositions"]) {
            self.scrubbingSpeedChangePositions = [decoder decodeObjectForKey:@"scrubbingSpeedChangePositions"];
        } else {
            self.scrubbingSpeedChangePositions = [self defaultScrubbingSpeedChangePositions];
        }
        
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
        [self constructSlider];
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NSCoding
////////////////////////////////////////////////////////////////////////

- (void)encodeWithCoder:(NSCoder *)coder {
    [super encodeWithCoder:coder];
    
    [coder encodeObject:self.scrubbingSpeeds forKey:@"scrubbingSpeeds"];
    [coder encodeObject:self.scrubbingSpeedChangePositions forKey:@"scrubbingSpeedChangePositions"];
    
    // No need to archive self.scrubbingSpeed as it is calculated from the arrays on init
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)layoutSubviews {
    [super layoutSubviews];

    // re-layout playable view
    self.playableValue = self.playableValue;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = self.bounds;
    bounds = CGRectInset(bounds, -10.f, -10.f);

    return CGRectContainsPoint(bounds, point);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIControl
////////////////////////////////////////////////////////////////////////

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    BOOL beginTracking = [super beginTrackingWithTouch:touch withEvent:event];
    
    if (beginTracking) {
		// Set the beginning tracking location to the centre of the current
		// position of the thumb. This ensures that the thumb is correctly re-positioned
		// when the touch position moves back to the track after tracking in one
		// of the slower tracking zones.
		CGRect thumbRect = [self thumbRectForBounds:self.bounds 
										  trackRect:[self trackRectForBounds:self.bounds]
											  value:self.value];
        self.beganTrackingLocation = CGPointMake(thumbRect.origin.x + thumbRect.size.width / 2.0f, 
												 thumbRect.origin.y + thumbRect.size.height / 2.0f); 
        _realPositionValue = self.value;
        
        // Fade in and update the popup view
        CGPoint touchPoint = [touch locationInView:self];
        // Check if the knob is touched. Only in this case show the popup-view
        if(CGRectContainsPoint(CGRectInset(thumbRect, -20.f, -20.f), touchPoint)) {
            [self positionAndUpdatePopupView];
            [self fadePopupViewInAndOut:YES]; 
        }
    }
    
    return beginTracking;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.tracking) {
        CGPoint previousLocation = [touch previousLocationInView:self];
        CGPoint currentLocation  = [touch locationInView:self];
        CGFloat trackingOffset = currentLocation.x - previousLocation.x;
        
        // Find the scrubbing speed that curresponds to the touch's vertical offset
        CGFloat verticalOffset = fabsf(currentLocation.y - self.beganTrackingLocation.y);
        NSUInteger scrubbingSpeedChangePosIndex = [self indexOfLowerScrubbingSpeed:self.scrubbingSpeedChangePositions forOffset:verticalOffset];        
        
        if (scrubbingSpeedChangePosIndex == NSNotFound) {
            scrubbingSpeedChangePosIndex = [self.scrubbingSpeeds count];
        }
        
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:scrubbingSpeedChangePosIndex - 1] floatValue];
        
        CGRect trackRect = [self trackRectForBounds:self.bounds];
        _realPositionValue = _realPositionValue + (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
		
		CGFloat valueAdjustment = self.scrubbingSpeed * (self.maximumValue - self.minimumValue) * (trackingOffset / trackRect.size.width);
		CGFloat thumbAdjustment = 0.0f;
        
        if (((self.beganTrackingLocation.y < currentLocation.y) && (currentLocation.y < previousLocation.y)) ||
            ((self.beganTrackingLocation.y > currentLocation.y) && (currentLocation.y > previousLocation.y)) ) {
            // We are getting closer to the slider, go closer to the real location
			thumbAdjustment = (_realPositionValue - self.value) / ( 1 + fabsf(currentLocation.y - self.beganTrackingLocation.y));
        }
        
		self.value += valueAdjustment + thumbAdjustment;
        
        if (self.continuous) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
        }
        
        [self positionAndUpdatePopupView];
    }
    
    return self.tracking;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.tracking) {
        self.scrubbingSpeed = [[self.scrubbingSpeeds objectAtIndex:0] floatValue];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
    
    [self fadePopupViewInAndOut:NO];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGScrubber
////////////////////////////////////////////////////////////////////////

- (void)setPlayableValue:(float)playableValue {
    if (playableValue != _playableValue) {
        _playableValue = playableValue;
    }
    
    if (playableValue == 0 || isnan(playableValue)) {
        self.playableView.frame = CGRectZero;
        return;
    }
    
    float valueDifference = self.maximumValue - self.minimumValue;
    float percentage = playableValue / valueDifference;
    CGRect trackRect = [self trackRectForBounds:self.bounds];

    trackRect = CGRectInset(trackRect, 0.f, 2.f);
    trackRect.size.width *= percentage;
    trackRect.size.width = MIN(trackRect.size.width, self.frame.size.width);
    trackRect = CGRectIntegral(trackRect);
    
    self.playableView.frame = trackRect;
}

- (void)setPlayableValueColor:(UIColor *)playableValueColor {
    if (playableValueColor != _playableValueColor) {
        _playableValueColor = playableValueColor;
        self.playableView.backgroundColor = playableValueColor;
    }
}

- (void)setPlayableValueRoundedRectRadius:(CGFloat)playableValueRoundedRectRadius {
    CALayer *layer = self.playableView.layer;
    
	layer.masksToBounds = YES;
	layer.cornerRadius = playableValueRoundedRectRadius;
	layer.borderWidth = 0.f;
}

- (CGFloat)playableValueRoundedRectRadius {
    return self.playableView.layer.cornerRadius;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

// Return the lowest index in the array of numbers passed in scrubbingSpeedPositions 
// whose value is smaller than verticalOffset.
- (NSUInteger)indexOfLowerScrubbingSpeed:(NSArray*)scrubbingSpeedPositions forOffset:(CGFloat)verticalOffset {
    for (NSUInteger i = 0; i < [scrubbingSpeedPositions count]; i++) {
        NSNumber *scrubbingSpeedOffset = [scrubbingSpeedPositions objectAtIndex:i];
        
        if (verticalOffset < [scrubbingSpeedOffset floatValue]) {
            return i;
        }
    }
    
    return NSNotFound; 
}

- (NSArray *)defaultScrubbingSpeeds {
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:1.0f],
            [NSNumber numberWithFloat:0.5f],
            [NSNumber numberWithFloat:0.25f],
            [NSNumber numberWithFloat:0.1f],
            nil];
}

- (NSArray *)defaultScrubbingSpeedChangePositions {
    return [NSArray arrayWithObjects:
            [NSNumber numberWithFloat:0.0f],
            [NSNumber numberWithFloat:50.0f],
            [NSNumber numberWithFloat:100.0f],
            [NSNumber numberWithFloat:150.0f],
            nil];
}

- (void)constructSlider {
    valuePopupView = [[NGSliderValuePopupView alloc] initWithFrame:CGRectZero];
    valuePopupView.backgroundColor = [UIColor clearColor];
    valuePopupView.alpha = 0.f;
    [self addSubview:valuePopupView];
}

- (void)fadePopupViewInAndOut:(BOOL)fadeIn {
    if (!self.showPopupDuringScrubbing) {
        valuePopupView.alpha = 0.f;
        return;
    }

    [UIView animateWithDuration:0.4
                     animations:^{
                         valuePopupView.alpha = fadeIn ? 1.f : 0.f;
                     }];
}

- (void)positionAndUpdatePopupView {
    CGRect thumbRect = [self thumbRectForBounds:self.bounds 
                                      trackRect:[self trackRectForBounds:self.bounds]
                                          value:self.value];
    CGFloat height = 35.f;
    CGRect popupRect = CGRectOffset(thumbRect, 0.f, -height - 5.f);
    
    valuePopupView.frame = CGRectInset(popupRect, -25.f, (CGRectGetHeight(popupRect) - height)/2.f);
    valuePopupView.time = self.value;
}

@end
