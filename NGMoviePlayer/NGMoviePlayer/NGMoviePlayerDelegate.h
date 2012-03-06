//
//  NGMoviePlayerDelegate.h
//  NGMoviePlayer
//
//  Created by Philip Messlehner on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

@class NGMoviePlayer;


@protocol NGMoviePlayerDelegate <NSObject>

@optional

- (void)player:(NGMoviePlayer *)player didChangeStatus:(AVPlayerStatus)playerStatus;
- (void)player:(NGMoviePlayer *)player didChangePlaybackRate:(float)rate;
- (void)player:(NGMoviePlayer *)player didChangeAirPlayActive:(BOOL)airPlayVideoActive;
- (void)playbackDidFinishWithPlayer:(NGMoviePlayer *)player;

// - (void)player:(NGMoviePlayer *)player zoomButtonPressed:(id)sender;

@end