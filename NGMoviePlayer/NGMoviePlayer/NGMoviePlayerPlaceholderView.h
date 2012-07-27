//
//  NGMoviePlayerPlaceholderView.h
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 27.07.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NGMoviePlayerPlaceholderView : UIView

@property (nonatomic, strong, readonly) UIButton *playButton;

/** Defaults to NO */
@property (nonatomic, assign) BOOL playButtonHidden;
/** Defaults to nil */
@property (nonatomic, copy) NSString *infoText;


- (void)addPlayButtonTarget:(id)target action:(SEL)action;

@end
