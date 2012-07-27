//
//  NGMoviePlayerViewController.m
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 26.07.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerViewController.h"
#import "NGMoviePlayer.h"


@interface NGMoviePlayerViewController () <NGMoviePlayerDelegate> {
    UIStatusBarStyle _statusBarStyle;
    BOOL _statusBarHidden;
}

@property (nonatomic, strong, readwrite) NGMoviePlayer *moviePlayer; // overwrite as readwrite

- (void)dismiss;

@end


@implementation NGMoviePlayerViewController

@synthesize moviePlayer = _moviePlayer;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithContentURL:(NSURL *)contentURL {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _statusBarStyle = [UIApplication sharedApplication].statusBarStyle;
        _statusBarHidden = [UIApplication sharedApplication].statusBarHidden;

        _moviePlayer = [[NGMoviePlayer alloc] initWithURL:contentURL];
        _moviePlayer.delegate = self;
        _moviePlayer.autostartWhenReady = YES;
    }

    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    return [self initWithContentURL:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - UIViewController
////////////////////////////////////////////////////////////////////////

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [UIColor blackColor];
    self.moviePlayer.view.controlStyle = NGMoviePlayerControlStyleFullscreen;
    [self.moviePlayer addToSuperview:self.view withFrame:self.view.bounds];
}

- (void)viewDidUnload {
    [super viewDidUnload];

    [self.moviePlayer.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.moviePlayer play];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (animated) {
        [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationFade];
    } else {
        [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationNone];
    }

    [[UIApplication sharedApplication] setStatusBarStyle:_statusBarStyle animated:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return YES;
    }

    return interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerDelegate
////////////////////////////////////////////////////////////////////////

- (void)moviePlayer:(NGMoviePlayer *)moviePlayer didChangeControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    if (controlStyle == NGMoviePlayerControlStyleInline) {
        [self dismiss];
    }
}

- (void)moviePlayer:(NGMoviePlayer *)moviePlayer didFinishPlaybackOfURL:(NSURL *)URL {
    [self dismiss];
}

- (void)moviePlayer:(NGMoviePlayer *)moviePlayer didFailToLoadURL:(NSURL *)URL {
    [self dismiss];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (void)dismiss {
    if (self.navigationController != nil) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self dismissModalViewControllerAnimated:YES];
    }
}

@end
