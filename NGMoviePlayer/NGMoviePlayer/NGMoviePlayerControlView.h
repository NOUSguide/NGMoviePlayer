//
//  NGMoviePlayerControlView.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlStyle.h"
#import "NGWeak.h"

extern NSString * const NGMoviePlayerControlViewTopControlsViewKey;
extern NSString * const NGMoviePlayerControlViewBottomControlsViewKey;
extern NSString * const NGMoviePlayerControlViewPlayPauseButtonKey;
extern NSString * const NGMoviePlayerControlViewScrubberKey;
extern NSString * const NGMoviePlayerControlViewRewindButtonKey;
extern NSString * const NGMoviePlayerControlViewForwardButtonKey;
extern NSString * const NGMoviePlayerControlViewAirPlayButtonKey;
extern NSString * const NGMoviePlayerControlViewVolumeViewKey;
extern NSString * const NGMoviePlayerControlViewVolumeControlKey;
extern NSString * const NGMoviePlayerControlViewZoomButtonKey;
extern NSString * const NGMoviePlayerControlViewCurrentTimeLabelKey;
extern NSString * const NGMoviePlayerControlViewRemainingTimeLabelKey;
extern NSString * const NGMoviePlayerControlViewtopButtonContainerKey;


@protocol NGMoviePlayerControlActionDelegate;
@class NGScrubber;
@class NGVolumeControl;


typedef enum {
    NGMoviePlayerControlViewZoomOutButtonPositionRight = 0,
    NGMoviePlayerControlViewZoomOutButtonPositionLeft
} NGMoviePlayerControlViewZoomOutButtonPosition;


@interface NGMoviePlayerControlView : UIView

@property (nonatomic, ng_weak) id<NGMoviePlayerControlActionDelegate> delegate;

/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

@property (nonatomic, strong) UIView *topControlsView;
@property (nonatomic, strong) UIView *bottomControlsView;

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
@property (nonatomic) NGMoviePlayerControlViewZoomOutButtonPosition zoomOutButtonPosition;

@property (nonatomic, copy) void (^layoutSubviewsBlock)(NGMoviePlayerControlStyle controlStyle, NSDictionary *controls);

- (void)updateScrubberWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

- (void)layoutSubviewsForControlStyle:(NGMoviePlayerControlStyle)controlStyle;

- (void)addTopControlsViewButton:(UIButton *)button;

@end
