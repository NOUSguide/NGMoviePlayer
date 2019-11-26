//
//  NGVolumeControl+NGCustomize.h
//  NGVolumeControl
//
//  Created by Tretter Matthias on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGVolumeControl.h"

/**
 Category that defines public API for customization.
 */
@interface NGVolumeControl (NGCustomize)

/**
 * Returns the image for the given volume. Subclasses can override to customize the volume control.
 */
- (UIImage *)imageForVolume:(float)volume;

/**
 Can be overridden to customize the appearance of the slider
 */
- (void)customizeSlider:(UISlider *)slider;

@end
