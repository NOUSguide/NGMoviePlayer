//
//  NGMoviePlayerFunctions.m
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 27.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerFunctions.h"

NSString* NGMoviePlayerGetTimeFormatted(NSTimeInterval currentTime) {
    if (currentTime < 0.) {
        return @"0:00";
    }
    
    NSInteger seconds = ((NSInteger)currentTime) % 60;
    NSInteger minutes = currentTime / 60;
    NSInteger hours = minutes / 60;
    minutes = ((NSInteger)minutes) % 60;
    
    if (hours > 0) {
        return [NSString stringWithFormat:@"%d:%02d:%02d", hours, minutes, seconds];
    } else {
        return [NSString stringWithFormat:@"%d:%02d", minutes, seconds];
    }

}

NSString* NGMoviePlayerGetRemainingTimeFormatted(NSTimeInterval currentTime, NSTimeInterval duration) {
    NSInteger remainingTime = duration-currentTime;
    NSString *formattedRemainingTime = NGMoviePlayerGetTimeFormatted(remainingTime);
    
    return [NSString stringWithFormat:@"-%@", formattedRemainingTime];
}
