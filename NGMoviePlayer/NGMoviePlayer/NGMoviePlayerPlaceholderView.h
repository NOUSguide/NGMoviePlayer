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
@property (nonatomic, strong, readonly) UILabel *infoLabel;
@property (nonatomic, strong, readonly) UIImageView *imageView;

/** Defaults to NO */
@property (nonatomic, assign) BOOL playButtonHidden;
/** Defaults to nil */
@property (nonatomic, copy) NSString *infoText;
/** Defaults to nil */
@property (nonatomic, strong) UIImage *image;


- (void)resetToInitialState;
- (void)addPlayButtonTarget:(id)target action:(SEL)action;

@end
