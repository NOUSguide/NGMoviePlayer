//
//  NGMoviePlayerDefaultLayout.h
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 10.09.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerLayout.h"


typedef enum {
    NGMoviePlayerControlViewZoomOutButtonPositionRight = 0,
    NGMoviePlayerControlViewZoomOutButtonPositionLeft
} NGMoviePlayerControlViewZoomOutButtonPosition;


@interface NGMoviePlayerDefaultLayout : NGMoviePlayerLayout

@property (nonatomic, readonly) NSArray *topControlsButtons;

@property (nonatomic, assign) BOOL scrubberHidden;
@property (nonatomic, assign) BOOL skipButtonsHidden;
@property (nonatomic, assign) CGFloat minWidthToDisplaySkipButtons;

/** the color of the scrubber */
@property (nonatomic, strong) UIColor *scrubberFillColor;
/** the padding between the buttons in topControlsView */
@property (nonatomic, assign) CGFloat topControlsViewButtonPadding;
/** the position of the zoomout-button in fullscreen-style */
@property (nonatomic, assign) NGMoviePlayerControlViewZoomOutButtonPosition zoomOutButtonPosition;


- (CGFloat)topControlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle;
- (CGFloat)bottomControlsViewHeightForControlStyle:(NGMoviePlayerControlStyle)controlStyle;

- (void)addTopControlsViewButton:(UIButton *)button;

@end
