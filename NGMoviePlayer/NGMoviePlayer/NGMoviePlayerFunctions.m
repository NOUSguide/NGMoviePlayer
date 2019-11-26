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
        return [NSString stringWithFormat:@"%ld:%02ld:%02ld", (long)hours, (long)minutes, (long)seconds];
    } else {
        return [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, (long)seconds];
    }

}

NSString* NGMoviePlayerGetRemainingTimeFormatted(NSTimeInterval currentTime, NSTimeInterval duration) {
    NSInteger remainingTime = duration-currentTime;
    NSString *formattedRemainingTime = NGMoviePlayerGetTimeFormatted(remainingTime);
    
    return [NSString stringWithFormat:@"-%@", formattedRemainingTime];
}
