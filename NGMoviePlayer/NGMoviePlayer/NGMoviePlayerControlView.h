//
//  NGMoviePlayerControlView.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerControlStyle.h"
#import "NGWeak.h"


@class NGMoviePlayerLayout;
@protocol NGMoviePlayerControlActionDelegate;


@interface NGMoviePlayerControlView : UIView

@property (nonatomic, ng_weak) id<NGMoviePlayerControlActionDelegate> delegate;

/** Controls whether the player controls are currently in fullscreen- or inlinestyle */
@property (nonatomic, assign) NGMoviePlayerControlStyle controlStyle;

@property (nonatomic, readonly) NSArray *topControlsViewButtons;
@property (nonatomic, assign) NSTimeInterval playableDuration;
@property (nonatomic, readonly, getter = isAirPlayButtonVisible) BOOL airPlayButtonVisible;


/******************************************
 @name Updating
 ******************************************/

- (void)updateScrubberWithCurrentTime:(NSTimeInterval)currentTime duration:(NSTimeInterval)duration;
- (void)updateButtonsWithPlaybackStatus:(BOOL)isPlaying;

@end
