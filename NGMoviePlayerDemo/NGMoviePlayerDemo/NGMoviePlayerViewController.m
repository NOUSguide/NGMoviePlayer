//
//  NGMoviePlayerViewController.m
//  NGMoviePlayerDemo
//
//  Created by Tretter Matthias on 13.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerViewController.h"

@interface NGMoviePlayerViewController () {
    NSUInteger activeCount_;
}

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) NGMoviePlayer *moviePlayer;
@property (nonatomic, strong) PSPushPopPressView *pppView;

@end

@implementation NGMoviePlayerViewController

@synthesize containerView = _containerView;
@synthesize moviePlayer = _moviePlayer;
@synthesize pppView = _pppView;

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.moviePlayer = [[NGMoviePlayer alloc] initWithURL:[NSURL URLWithString:@"http://office.nousguide.com/streaming/qa.m3u8"]];
    self.containerView = [[UIView alloc] initWithFrame:self.view.bounds];
    self.containerView.backgroundColor = [UIColor underPageBackgroundColor];
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.pppView = [[PSPushPopPressView alloc] initWithFrame:CGRectMake(10.f, 10.f, self.containerView.bounds.size.width-20.f, self.containerView.bounds.size.height/2-20.f)];
    self.pppView.allowSingleTapSwitch = NO;
    self.pppView.pushPopPressViewDelegate = self;
    self.pppView.backgroundColor = [UIColor redColor];
    self.pppView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.moviePlayer.delegate = self;
    self.moviePlayer.view.frame = self.pppView.bounds;
    self.moviePlayer.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.pppView addSubview:self.moviePlayer.view];
    [self.containerView addSubview:self.pppView];
    
    [self.view addSubview:self.containerView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self.moviePlayer play];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayer
////////////////////////////////////////////////////////////////////////

- (void)player:(NGMoviePlayer *)player didChangeControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleInline) {
        [self.pppView moveToOriginalFrameAnimated:YES];
    } else {
        [self.pppView moveToFullscreenWindowAnimated:YES];
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark PSPushPopPressViewDelegate
///////////////////////////////////////////////////////////////////////////////////////////////////

- (void)pushPopPressViewDidStartManipulation:(PSPushPopPressView *)pushPopPressView {
    activeCount_++;
    [UIView animateWithDuration:0.45f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        // note that we can't just apply this transform to self.view, we would loose the
        // already applied transforms (like rotation)
        self.containerView.transform = CGAffineTransformMakeScale(0.95, 0.95);
        pushPopPressView.alpha = 0.35f;
    } completion:nil];
}

- (void)pushPopPressViewDidFinishManipulation:(PSPushPopPressView *)pushPopPressView {
    if (activeCount_ > 0) {
        activeCount_--;
        if (activeCount_ == 0) {
            [UIView animateWithDuration:0.45f delay:0.f options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                self.containerView.transform = CGAffineTransformIdentity;
                pushPopPressView.alpha = 1.f;
            } completion:nil];
        }
    }
}

- (void)pushPopPressViewWillAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView duration:(NSTimeInterval)duration {
    if (self.moviePlayer.fullscreen) {
        self.moviePlayer.fullscreen = NO;
        self.moviePlayer.view.controlsVisible = NO;
    }
}

- (void)pushPopPressViewDidAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView {
    // update autoresizing mask to adapt to width only
    pushPopPressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    if (!self.moviePlayer.view.controlsVisible) {
        [self.moviePlayer.view setControlsVisible:YES animated:YES];
    }
    
    // ensure the view doesn't overlap with another (possible fullscreen) view
    [self.containerView sendSubviewToBack:pushPopPressView];
}

- (void)pushPopPressViewWillAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView duration:(NSTimeInterval)duration {
    if (!self.moviePlayer.fullscreen) {
        self.moviePlayer.fullscreen = YES;
        self.moviePlayer.view.controlsVisible = NO;
    }
}

- (void)pushPopPressViewDidAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView {
    // update autoresizing mask to adapt to borders
    pushPopPressView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    if (!self.moviePlayer.view.controlsVisible) {
        [self.moviePlayer.view setControlsVisible:YES animated:YES];
    }
    
    [pushPopPressView layoutIfNeeded];
}

- (BOOL)pushPopPressViewShouldAllowTapToAnimateToOriginalFrame:(PSPushPopPressView *)pushPopPressView {
    // NSLog(@"pushPopPressViewShouldAllowTapToAnimateToOriginalFrame: %@", pushPopPressView);
    return YES;
}

- (BOOL)pushPopPressViewShouldAllowTapToAnimateToFullscreenWindowFrame:(PSPushPopPressView *)pushPopPressView {
    // NSLog(@"pushPopPressViewShouldAllowTapToAnimateToFullscreenWindowFrame: %@", pushPopPressView);
    return YES;
}

- (void)pushPopPressViewDidReceiveTap:(PSPushPopPressView *)pushPopPressView {
    // NSLog(@"pushPopPressViewDidReceiveTap: %@", pushPopPressView);
}

@end
