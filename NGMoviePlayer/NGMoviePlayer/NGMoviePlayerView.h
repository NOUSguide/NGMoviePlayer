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

@class NGMoviePlayerLayerView;
@class NGMoviePlayerControlView;


@interface NGMoviePlayerView : UIView

/** The wrapped player layer */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

/** The view that contains the controls and fades in/out */
@property (nonatomic, strong, readonly) NGMoviePlayerControlView *controlsView;

/** flag that indicates whether the player controls are currently visible. changes are made non-animated */
@property (nonatomic, assign) BOOL controlsVisible;
/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

/**
 Changes the visibility of the controls, can be animated with a fade.
 */
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;

/** Updates the UI to reflect the current time */
- (void)updateWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)updateWithPlaybackStatus:(BOOL)isPlaying;

@end
