//
//  NGMoviePlayerView.h
//  NGMoviePlayer
//
//  Created by Philip Messlehner on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//
//  Based on HSPlayer by Simon Blommegård, further work by Philip Messlehner.
//  Created by Simon Blommegård on 2011-11-26.
//  Copyright (c) 2011 Doubleint. All rights reserved.

#import "NGMoviePlayerControlStyle.h"
#import "NGWeak.h"
#import "NGMoviePlayerScreenState.h"


@class NGMoviePlayerLayerView;
@class NGMoviePlayerControlView;
@protocol NGMoviePlayerControlActionDelegate;


@interface NGMoviePlayerView : UIView

@property (nonatomic, ng_weak) id<NGMoviePlayerControlActionDelegate> delegate;

/** The wrapped player layer */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

/** The view that contains the controls and fades in/out */
@property (nonatomic, strong, readonly) NGMoviePlayerControlView *controlsView;
/** The placeholder view that gets shown before the movie plays */
@property (nonatomic, strong) UIView *placeholderView;

/** flag that indicates whether the player controls are currently visible. changes are made non-animated */
@property (nonatomic, assign) BOOL controlsVisible;
/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

/** indicates, if status bar should be shown when displaying controls in fullscreen. default YES */
@property (nonatomic, assign) BOOL shouldShowStatusBarInFullScreenMode;

@property (nonatomic, readonly) CGFloat topControlsViewHeight;
@property (nonatomic, readonly) CGFloat bottomControlsViewHeight;

@property (nonatomic, readonly) NGMoviePlayerScreenState screenState;

/** Changes the visibility of the controls, can be animated with a fade */
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;
/** Hides the placeholder view with the play button */
- (void)hidePlaceholderViewAnimated:(BOOL)animated;
/** shows the placeholder view with the play button */
- (void)showPlaceholderViewAnimated:(BOOL)animated;

/** setups the UI corresponding to the State (Airplay, VGA, or just playing) */
- (void)updateViewsForCurrentScreenState;

- (void)stopFadeOutControlsViewTimer;
- (void)restartFadeOutControlsViewTimer;

/** Updates the UI to reflect the current time */
- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)updateWithPlaybackStatus:(BOOL)isPlaying;

/** Adds an overlay view to the view that is beneath the controls but on top of the video */
- (void)addVideoOverlayView:(UIView *)overlayView;

/** 
 Performs the actions on the playerView to start playback. 
 Call this method on your custom placeholderView implementation 
 
 @param playControl the control used to start playback

 */
- (void)handlePlayButtonPress:(id)playControl;

@end
