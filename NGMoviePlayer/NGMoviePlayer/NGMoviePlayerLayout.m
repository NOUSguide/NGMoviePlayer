//
//  NGMoviePlayerLayout.m
//  NGMoviePlayer
//
//  Created by Matthias Tretter on 10.09.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

#import "NGMoviePlayerLayout.h"
#import "NGMoviePlayer.h"
#import "NGMoviePlayerControlView+NGPrivate.h"


@interface NGMoviePlayerLayout ()

@property (nonatomic, strong, readwrite) UIView *topControlsView;
@property (nonatomic, strong, readwrite) UIView *bottomControlsView;
@property (nonatomic, strong, readwrite) UIView *topControlsContainerView;

@property (nonatomic, strong, readwrite) UIButton *playPauseControl;
@property (nonatomic, strong, readwrite) UIButton *rewindControl;
@property (nonatomic, strong, readwrite) UIButton *forwardControl;

@property (nonatomic, strong, readwrite) NGScrubber *scrubberControl;
@property (nonatomic, strong, readwrite) UILabel *currentTimeLabel;
@property (nonatomic, strong, readwrite) UILabel *remainingTimeLabel;

@property (nonatomic, strong, readwrite) NGVolumeControl *volumeControl;
@property (nonatomic, strong, readwrite) UIControl *airPlayControlContainer;
@property (nonatomic, strong, readwrite) MPVolumeView *airPlayControl;

@property (nonatomic, strong, readwrite) UIButton *zoomControl;

@end


@implementation NGMoviePlayerLayout

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerLayout
////////////////////////////////////////////////////////////////////////

- (void)setMoviePlayer:(NGMoviePlayer *)moviePlayer {
    if (moviePlayer != _moviePlayer) {
        _moviePlayer = moviePlayer;

        // update control references
        self.topControlsView = moviePlayer.view.controlsView.topControlsView;
        self.bottomControlsView = moviePlayer.view.controlsView.bottomControlsView;
        self.topControlsContainerView = moviePlayer.view.controlsView.topControlsContainerView;

        self.playPauseControl = moviePlayer.view.controlsView.playPauseControl;
        self.rewindControl = moviePlayer.view.controlsView.rewindControl;
        self.forwardControl = moviePlayer.view.controlsView.forwardControl;

        self.scrubberControl = moviePlayer.view.controlsView.scrubberControl;
        self.currentTimeLabel = moviePlayer.view.controlsView.currentTimeLabel;
        self.remainingTimeLabel = moviePlayer.view.controlsView.remainingTimeLabel;

        self.volumeControl = moviePlayer.view.controlsView.volumeControl;
        self.airPlayControlContainer = moviePlayer.view.controlsView.airPlayControlContainer;
        self.airPlayControl = moviePlayer.view.controlsView.airPlayControl;

        self.zoomControl = moviePlayer.view.controlsView.zoomControl;
    }
}

- (NGMoviePlayerControlView *)controlsView {
    return self.moviePlayer.view.controlsView;
}

- (NGMoviePlayerControlStyle)controlStyle {
    return self.moviePlayer.view.controlStyle;
}

- (CGFloat)width {
    return self.moviePlayer.view.controlsView.bounds.size.width;
}

- (CGFloat)height {
    return self.moviePlayer.view.controlsView.bounds.size.height;
}

- (BOOL)isAirPlayControlVisible {
    if (self.airPlayControl == nil) {
        return NO;
    }

    for (UIView *subview in self.airPlayControl.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            if (subview.alpha == 0.f || subview.hidden) {
                return NO;
            }
        }
    }

    return YES;
}

- (void)updateControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    [self customizeTopControlsViewWithControlStyle:controlStyle];
    [self customizeBottomControlsViewWithControlStyle:controlStyle];
    [self customizeControlsWithControlStyle:controlStyle];
    
    [self invalidateLayout];
}

- (void)invalidateLayout {
    [self.controlsView setNeedsLayout];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayerLayout Protocol
////////////////////////////////////////////////////////////////////////

- (void)customizeTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Subclasses must implement
}

- (void)customizeBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Subclasses must implement
}

- (void)customizeControlsWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Sublasses must implement
}

- (void)layoutTopControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Subclasses must implement
}

- (void)layoutBottomControlsViewWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Subclasses must implement
}

- (void)layoutControlsWithControlStyle:(NGMoviePlayerControlStyle)controlStyle {
    // Subclasses must implement
}

@end
