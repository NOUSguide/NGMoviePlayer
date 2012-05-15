//
//  NGMoviePlayerDelegate.h
//  NGMoviePlayer
//
//  Created by Philip Messlehner on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlStyle.h"

@class NGMoviePlayer;


@protocol NGMoviePlayerDelegate <NSObject>

@optional

- (void)player:(NGMoviePlayer *)player didChangeStatus:(AVPlayerStatus)playerStatus;
- (void)player:(NGMoviePlayer *)player didChangePlaybackRate:(float)rate;
- (void)player:(NGMoviePlayer *)player didChangeAirPlayActive:(BOOL)airPlayVideoActive;
- (void)player:(NGMoviePlayer *)player didChangeControlStyle:(NGMoviePlayerControlStyle)controlStyle;
- (void)player:(NGMoviePlayer *)player didFailToLoadURL:(NSURL *)URL;
- (void)player:(NGMoviePlayer *)player didUpdateCurrentTime:(NSTimeInterval)currentTime;

- (void)playbackDidStartWithPlayer:(NGMoviePlayer *)player;
- (void)playbackDidPauseWithPlayer:(NGMoviePlayer *)player;
- (void)playbackDidFinishWithPlayer:(NGMoviePlayer *)player;

- (void)playerDidBeginScrubbing:(NGMoviePlayer *)player;
- (void)playerDidEndScrubbing:(NGMoviePlayer *)player;

@end