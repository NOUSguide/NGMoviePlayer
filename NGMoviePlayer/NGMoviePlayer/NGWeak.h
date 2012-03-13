//
//  NGWeak.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

/**  If compiled for iOS 5 up zeroing weak refs are used  */

#if __has_feature(objc_arc_weak)
    #define ng_weak  weak
    #define __ng_weak __weak
#else
    #define ng_weak  unsafe_unretained
    #define __ng_weak __unsafe_unretained
#endif