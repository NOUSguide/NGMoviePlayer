//
//  NGMoviePlayerVideoGravity.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 06.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

typedef enum {
    NGMoviePlayerVideoGravityResizeAspect = 0,  // default
    NGMoviePlayerVideoGravityResizeAspectFill,
    NGMoviePlayerVideoGravityResize,
} NGMoviePlayerVideoGravity;


NS_INLINE NSString* NGAVLayerVideoGravityFromNGMoviePlayerVideoGravity(NGMoviePlayerVideoGravity gravity) {
    switch (gravity) {    
        case NGMoviePlayerVideoGravityResizeAspectFill: {
            return AVLayerVideoGravityResizeAspectFill;
        }

        case NGMoviePlayerVideoGravityResize: {
            return AVLayerVideoGravityResize;
        }
            
        default:
        case NGMoviePlayerVideoGravityResizeAspect: {
            return AVLayerVideoGravityResizeAspect;
        }
    }
}

NS_INLINE NGMoviePlayerVideoGravity NGMoviePlayerVideoGravityFromAVLayerVideoGravity(NSString *gravity) {
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        return NGMoviePlayerVideoGravityResizeAspectFill;
    }
    
    if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        return NGMoviePlayerVideoGravityResize;
    }
    
    // default
    return NGMoviePlayerVideoGravityResizeAspect;
}

NS_INLINE NSString* NGAVLayerVideoGravityNext(NSString *gravity) {
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        return AVLayerVideoGravityResizeAspectFill;
    }
    
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        return AVLayerVideoGravityResize;
    }
    
    // default
    return AVLayerVideoGravityResizeAspect;
}