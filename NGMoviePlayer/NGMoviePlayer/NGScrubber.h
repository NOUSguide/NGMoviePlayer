//
//  NGSlider.h
//  NGMoviePlayer
//
//  Created by Philip Messlehner on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//
//  This class is based on Ole Begemann's fantastic OBSlider: github.com/ole/OBSlider
//  Popup with current value based on: http://blog.neuwert-media.com/2011/04/customized-uislider-with-visual-value-tracking/
//  ARCified and cleaned up by Philip Messlehner and Matthias Tretter


@interface NGScrubber : UISlider

@property (atomic, assign, readonly) float scrubbingSpeed;
@property (atomic, strong) NSArray *scrubbingSpeeds;
@property (atomic, strong) NSArray *scrubbingSpeedChangePositions;

@property (nonatomic, assign) float playableValue;

@property (nonatomic, strong) UIColor *playableValueColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, strong) UIColor *fillColor UI_APPEARANCE_SELECTOR;
@property (nonatomic, assign) CGFloat playableValueRoundedRectRadius UI_APPEARANCE_SELECTOR;

// defaults to YES
@property (nonatomic, assign) BOOL showPopupDuringScrubbing;

@end
