//
//  NGMoviePlayerPlaceholderView.m
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 27.07.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerPlaceholderView.h"


@interface NGMoviePlayerPlaceholderView ()

@property (nonatomic, strong) UIActivityIndicatorView *activityView;

@end


@implementation NGMoviePlayerPlaceholderView

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blackColor];
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        _imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.hidden = YES;
        [self addSubview:_imageView];

        UIImage *playImage = [UIImage imageNamed:@"NGMoviePlayer.bundle/playVideo"];

        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _playButton.frame = (CGRect){.size = playImage.size};
        _playButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
        _playButton.center = CGPointMake(self.bounds.size.width/2.f, self.bounds.size.height/2.f);
        [_playButton setImage:playImage forState:UIControlStateNormal];
        [_playButton addTarget:self action:@selector(handlePlayButtonPress:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:_playButton];

        _infoLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _infoLabel.backgroundColor = [UIColor clearColor];
        _infoLabel.textColor = [UIColor whiteColor];
        _infoLabel.font = [UIFont systemFontOfSize:14.f];
        _infoLabel.numberOfLines = 0;
        _infoLabel.lineBreakMode = NSLineBreakByWordWrapping | NSLineBreakByTruncatingTail;
        _infoLabel.textAlignment = NSTextAlignmentCenter;
        _infoLabel.hidden = YES;
        [self addSubview:_infoLabel];
    }

    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIView
////////////////////////////////////////////////////////////////////////

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat centerX = self.playButton.center.x;
    CGFloat topY = self.playButton.frame.origin.y + self.playButton.frame.size.height + 5.f;

    self.infoLabel.center = CGPointMake(centerX, topY + self.infoLabel.frame.size.height/2.f);
    self.infoLabel.frame = CGRectIntegral(self.infoLabel.frame);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerPlaceholderView
////////////////////////////////////////////////////////////////////////

- (void)setPlayButtonHidden:(BOOL)playButtonHidden {
    self.playButton.hidden = playButtonHidden;
}

- (BOOL)playButtonHidden {
    return self.playButton.hidden;
}

- (void)setInfoText:(NSString *)infoText {
    self.infoLabel.text = infoText;

    if (infoText.length == 0) {
        self.infoLabel.hidden = YES;
    } else {
        [self.infoLabel sizeToFit];
        self.infoLabel.hidden = NO;
        [self setNeedsLayout];
    }
}

- (NSString *)infoText {
    return self.infoLabel.text;
}

- (void)addPlayButtonTarget:(id)target action:(SEL)action {
    [self.playButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
}

- (void)setImage:(UIImage *)image {
    self.imageView.image = image;
    self.imageView.hidden = (image == nil);
}

- (UIImage *)image {
    return self.imageView.image;
}

- (void)resetToInitialState {
    [self.activityView stopAnimating];
    [self.activityView removeFromSuperview];
    self.playButton.hidden = NO;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)handlePlayButtonPress:(id)sender {
    [self.activityView removeFromSuperview];

    self.activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.activityView.hidesWhenStopped = YES;
    self.activityView.center = self.playButton.center;
    self.activityView.autoresizingMask = self.playButton.autoresizingMask;
    [self.playButton.superview addSubview:self.activityView];
    self.playButton.hidden = YES;

    [self.activityView startAnimating];
}

@end
