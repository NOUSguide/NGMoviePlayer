//
//  NGMoviePlayerControlViewDelegate.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

typedef enum {
    NGMoviePlayerControlActionTogglePlayPause,
    NGMoviePlayerControlActionToggleZoomState,
    NGMoviePlayerControlActionSkipBackwards,
    NGMoviePlayerControlActionSkipForwards,
    NGMoviePlayerControlActionBeginScrubbing,
    NGMoviePlayerControlActionScrubbingValueChanged,
    NGMoviePlayerControlActionEndScrubbing
} NGMoviePlayerControlAction;


@protocol NGMoviePlayerControlViewDelegate <NSObject>

- (void)moviePlayerControl:(id)control didPerformAction:(NGMoviePlayerControlAction)action;

@end