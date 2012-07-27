//
//  NGMoviePlayerViewController.h
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 26.07.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>


@class NGMoviePlayer;


@interface NGMoviePlayerViewController : UIViewController

@property (nonatomic, strong, readonly) NGMoviePlayer *moviePlayer;

- (id)initWithContentURL:(NSURL *)contentURL;

@end
