//
//  NGVolumeControlDelegate.h
//  NGVolumeControl
//
//  Created by Matthias Tretter on 15.10.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>


@class NGVolumeControl;


@protocol NGVolumeControlDelegate <NSObject>

@optional

- (void)volumeControlWillExpand:(NGVolumeControl *)volumeControl;
- (void)volumeControlDidExpand:(NGVolumeControl *)volumeControl;
- (void)volumeControlWillShrink:(NGVolumeControl *)volumeControl;
- (void)volumeControlDidShrink:(NGVolumeControl *)volumeControl;
- (void)volumeControl:(NGVolumeControl *)volumeControl didChangeOldVolume:(float)oldVolume toNewVolume:(float)newVolume;

@end
