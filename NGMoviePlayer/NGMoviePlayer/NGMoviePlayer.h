//
//  NGMoviePlayer.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerDelegate.h"
#import "NGMoviePlayerView.h"
#import "NGMoviePlayerVideoGravity.h"
#import "NGWeak.h"

@interface NGMoviePlayer : NSObject

/** The wrapped AVPlayer object */
@property (nonatomic, strong, readonly) AVPlayer *player;
/** The player view */
@property (nonatomic, strong, readonly) NGMoviePlayerView *view;

/** The URL of the video to play, start player by setting the URL */
@property (nonatomic, copy) NSURL *URL;
/** flag to indicate if the player is currently playing */
@property (nonatomic, readonly, getter = isPlaying) BOOL playing;
/** flag that indicates whether the player is currently scrubbing */
@property (nonatomic, assign, readonly, getter = isScrubbing) BOOL scrubbing;
/** The delegate of the player */
@property (nonatomic, ng_weak) id<NGMoviePlayerDelegate> delegate;
/** The gravity of the video */
@property (nonatomic, assign) NGMoviePlayerVideoGravity videoGravity;
/** The control state */
@property (nonatomic, assign, getter = isFullscreen) BOOL fullscreen;

/** AirPlay is only supported on >= iOS 5, defaults to YES */
@property (nonatomic, assign) BOOL airPlayActive;
/** flag to indicate whether the video autoplays when it's ready loading, defaults to NO */
@property (nonatomic, assign) BOOL autostartWhenReady;

/** current playback time of the player */
@property (nonatomic, assign) NSTimeInterval currentTime;
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 Sets the audio session to MediaPlayback and thefore ignores the system mute switch,
 is called by default
 */
+ (void)ignoreSystemMuteSwitch;

- (id)init;
- (id)initWithURL:(NSURL *)URL;

- (void)play;
- (void)pause;


@end
