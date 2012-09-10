//
//  NGMoviePlayerLayout.h
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 10.09.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NGMoviePlayerControlStyle.h"


@class NGVolumeControl;
@class NGScrubber;


//@protocol NGMoviePlayerLayout <NSObject>
//
///** the current control style */
//@property (nonatomic, readonly) NGMoviePlayerControlStyle controlStyle;
//
///** customizes the appearance of the top controls view. only get's called when the controlStyle changes */
//- (void)customizeTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle;
//- (void)customizeBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle;
//
///** positions the top controls view */
//- (void)layoutTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle;
///** positions the bottom controls view */
//- (void)layoutBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle;
//
///** layouts the controls for the given control style */
//- (void)layoutControls;
//
//@end
//
//
//@interface NGMoviePlayerLayout : NSObject <NGMoviePlayerLayout>
//
//@property (nonatomic, strong, readonly) UIView *topControlsView;
//@property (nonatomic, strong, readonly) UIView *bottomControlsView;
//@property (nonatomic, strong, readonly) UIView *topControlsContainerView;
//
//@property (nonatomic, strong, readonly) UIButton *playPauseControl;
//@property (nonatomic, strong, readonly) UIButton *rewindControl;
//@property (nonatomic, strong, readonly) UIButton *forwardControl;
//
//@property (nonatomic, strong, readonly) NGScrubber *scrubberControl;
//@property (nonatomic, strong, readonly) UILabel *currentTimeLabel;
//@property (nonatomic, strong, readonly) UILabel *remainingTimeLabel;
//
//@property (nonatomic, strong, readonly) NGVolumeControl *volumeControl;
//@property (nonatomic, strong, readonly) UIControl *airPlayControlContainer;
//@property (nonatomic, strong, readonly) MPVolumeView *airPlayControl;
//
//@property (nonatomic, strong, readonly) UIButton *zoomControl;
//
//@end
