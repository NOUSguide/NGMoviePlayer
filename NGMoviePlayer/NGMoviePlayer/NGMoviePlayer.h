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
#import "NGMoviePlayerAudioSessionCategory.h"
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

/** AirPlay is only supported on >= iOS 5, defaults to YES */
@property (nonatomic, assign, getter = isAirPlayActive) BOOL airPlayActive;
/** flag to indicate whether the video autoplays when it's ready loading, defaults to NO */
@property (nonatomic, assign) BOOL autostartWhenReady;

/** current playback time of the player */
@property (nonatomic, assign) NSTimeInterval currentTime;
/** total duration of played video */
@property (nonatomic, readonly) NSTimeInterval duration;
/** currently downloaded duration which is already playable */
@property (nonatomic, readonly) NSTimeInterval playableDuration;

/**
 By changing the audio session category you can influence how your audio output interacts with
 other system audio output. Default category is AudioSessionCategoryPlackback, which ignores the
 system volume mute switch.
 */
+ (void)setAudioSessionCategory:(NGMoviePlayerAudioSessionCategory)audioSessionCategory;

- (id)init;
- (id)initWithURL:(NSURL *)URL;

- (void)play;
- (void)pause;

/**
 Convenience method to set frame of view and add to superview
 */
- (void)addToSuperview:(UIView *)view withFrame:(CGRect)frame;

@end
