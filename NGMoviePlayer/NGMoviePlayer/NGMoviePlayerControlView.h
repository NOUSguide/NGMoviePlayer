//
//  NGMoviePlayerControlView.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlStyle.h"

@class NGSlider;


@interface NGMoviePlayerControlView : UIView

/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

/** the slider indicating the current playback time */
@property (nonatomic, strong, readonly) NGSlider *scrubber;

/** the color of the scrubber in fullscreen */
@property (nonatomic, strong) UIColor *scrubberFillColor;


- (void)updateScrubberWithCurrentTime:(NSInteger)currentTime duration:(NSInteger)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

@end
