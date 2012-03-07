//
//  NGSlider.h
//  NGMoviePlayer
//
//  Created by Philip Messlehner on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//
//  This class is based on Ole Begemann's fantastic OBSlider: github.com/ole/OBSlider
//  ARCified and cleaned up by Philip Messlehner and Matthias Tretter


@interface NGSlider : UISlider

@property (atomic, assign, readonly) float scrubbingSpeed;
@property (atomic, strong) NSArray *scrubbingSpeeds;
@property (atomic, strong) NSArray *scrubbingSpeedChangePositions;

@end
