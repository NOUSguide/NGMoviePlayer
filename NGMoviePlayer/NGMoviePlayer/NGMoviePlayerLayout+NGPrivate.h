//
//  NGMoviePlayerLayout+NGPrivate.h
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 10.09.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerLayout.h"


@interface NGMoviePlayerLayout (NGPrivate)

@property (nonatomic, ng_weak, readwrite) NGMoviePlayer *moviePlayer;

@end
