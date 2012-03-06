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


@class NGMoviePlayerLayerView;


@interface NGMoviePlayerView : UIView

/** The wrapped AVPlayer object */
@property (nonatomic, strong, readonly) AVPlayer *player;
/** The wrapped player layer */
@property (nonatomic, readonly) AVPlayerLayer *playerLayer;

/** flag that indicates whether the player controls are currently visible. changes are made non-animated */
@property (nonatomic, assign) BOOL controlsVisible;
/** Controls whether the player is currently in full-screen mode or not */
@property (nonatomic, assign) BOOL fullScreen;

/**
 Changes the visibility of the controls, can be animated with a fade.
 */
- (void)setControlsVisible:(BOOL)controlsVisible animated:(BOOL)animated;

@end
