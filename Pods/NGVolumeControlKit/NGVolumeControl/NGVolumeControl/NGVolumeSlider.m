//
//  NGVolumeSlider.m
//  NGVolumeControl
//
//  Created by Matthias Tretter on 15.10.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGVolumeSlider.h"

@implementation NGVolumeSlider

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = CGRectInset(self.bounds, -10.f, -30.f);
    //bounds = CGRectApplyAffineTransform(bounds, self.transform);

    return CGRectContainsPoint(bounds, point);
}

@end
