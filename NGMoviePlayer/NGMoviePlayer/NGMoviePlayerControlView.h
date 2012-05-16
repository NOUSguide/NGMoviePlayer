//
//  NGMoviePlayerControlView.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlStyle.h"
#import "NGWeak.h"

@protocol NGMoviePlayerControlActionDelegate;
@class NGScrubber;
@class NGVolumeControl;

typedef enum {
    NGMoviePlayerControlViewZoomOuttButtonPositionRight = 0,
    NGMoviePlayerControlViewZoomOuttButtonPositionLeft
} NGMoviePlayerControlViewZoomOutButtonPosition;

@interface NGMoviePlayerControlView : UIView

@property (nonatomic, ng_weak) id<NGMoviePlayerControlActionDelegate> delegate;

@property (nonatomic, strong) UIView *topControlsView;
@property (nonatomic, strong) UIView *bottomControlsView;

/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

/** the slider indicating the current playback time */
@property (nonatomic, strong, readonly) NGScrubber *scrubber;
@property (nonatomic, assign) NSTimeInterval playableDuration;
/** the super-fancy volume control */
@property (nonatomic, strong) NGVolumeControl *volumeControl;

/** the color of the scrubber in fullscreen */
@property (nonatomic, strong) UIColor *scrubberFillColor;

/** the padding between the buttons in topControlsView */
@property (nonatomic) CGFloat topControlsViewButtonPadding;

/** the position of the zoomout-button in fullscreen-style */
@property (nonatomic) NGMoviePlayerControlViewZoomOutButtonPosition *zoomOutButtonPosition; 

- (void)updateScrubberWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

- (void)addTopControlsViewButton:(UIButton *)button;

@end
