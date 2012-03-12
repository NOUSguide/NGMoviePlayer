#import "NGMoviePlayer.h"
#import "NGMoviePlayerView.h"
#import "NGMoviePlayerLayerView.h"


static char playerItemStatusContext;
static char playerItemDurationContext;
static char playerCurrentItemContext;
static char playerRateContext;
static char playerAirPlayVideoActiveContext;

@interface NGMoviePlayer () {
    // flags for methods implemented in the delegate
    struct {
        unsigned int didChangeStatus:1;
        unsigned int didChangePlaybackRate:1;
		unsigned int didChangeAirPlay:1;
		unsigned int didFinishPlayback:1;
        unsigned int didFailToLoadURL:1;
	} _delegateFlags;
    
    BOOL _seekToZeroBeforePlay;
    float _rateToRestoreAfterScrubbing;
}

@property (nonatomic, strong, readwrite) AVPlayer *player;  // re-defined as read/write
@property (nonatomic, assign, readwrite, getter = isScrubbing) BOOL scrubbing; // re-defined as read/write
@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, readonly) CMTime CMDuration;
@property (nonatomic, strong) id playerTimeObserver;

- (void)startObservingPlayerTimeChanges;
- (void)stopObservingPlayerTimeChanges;

- (void)beginScrubbing;
- (void)endScrubbing;

- (void)togglePlaybackState;

// player is ready to play
- (void)doneLoadingAsset:(AVAsset *)asset withKeys:(NSArray *)keys;

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification;

@end

@implementation NGMoviePlayer

@dynamic player;

@synthesize playerView = _playerView;
@synthesize URL = _URL;
@synthesize scrubbing = _scrubbing;
@synthesize delegate = _delegate;
@synthesize airPlayActive = _airPlayActive;
@synthesize asset = _asset;
@synthesize playerItem = _playerItem;
@synthesize playerTimeObserver = _playerTimeObserver;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)initWithURL:(NSURL *)URL {
    if ((self = [super init])) {
        _seekToZeroBeforePlay = YES;
        _airPlayActive = YES;
        
        // calling setter here on purpose
        self.URL = URL;
    }
    
    return self;
}

- (id)init {
    return [self initWithURL:nil];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayer Video Playback
////////////////////////////////////////////////////////////////////////

- (void)play {
    
}

- (void)pause {
    [self.player pause];
}

- (void)togglePlaybackState {
    if (self.playing) {
        [self pause];
    } else {
        [self play]; 
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayer Properties
////////////////////////////////////////////////////////////////////////

- (AVPlayer *)player {
    return self.playerView.playerLayer.player;
}

- (void)setPlayer:(AVPlayer *)player {
    if (player != self.playerView.playerLayer.player) {
        [self.playerView.playerLayer setPlayer:player];
        
        // Support AirPlay?
        if (self.airPlayActive && [player respondsToSelector:@selector(allowsAirPlayVideo)]) {
            [player setAllowsAirPlayVideo:YES];
            [player setUsesAirPlayVideoWhileAirPlayScreenIsActive:YES];
            
            [player addObserver:self
                     forKeyPath:@"airPlayVideoActive"
                        options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                        context:&playerAirPlayVideoActiveContext];
        }
    }
}

- (void)setURL:(NSURL *)URL {
    if (_URL != URL) {
        [self willChangeValueForKey:@"URL"];
        _URL = URL;
        [self didChangeValueForKey:@"URL"];
        
        if (URL != nil) {
            // Create Asset, and load
            [self setAsset:[AVURLAsset URLAssetWithURL:URL options:nil]];
            NSArray *keys = [NSArray arrayWithObjects:@"tracks", @"playable", nil];
            
            [self.asset loadValuesAsynchronouslyForKeys:keys completionHandler:^{
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self doneLoadingAsset:self.asset withKeys:keys];
                });
            }];
        }
    }
}

- (void)setDelegate:(id<NGMoviePlayerDelegate>)delegate {
    if (delegate != _delegate) {
        _delegate = delegate;
        
        _delegateFlags.didChangeStatus = [delegate respondsToSelector:@selector(player:didChangeStatus:)];
        _delegateFlags.didChangePlaybackRate = [delegate respondsToSelector:@selector(player:didChangePlaybackRate:)];
        _delegateFlags.didChangeAirPlay = [delegate respondsToSelector:@selector(player:didChangeAirPlayActive:)];
        _delegateFlags.didFinishPlayback = [delegate respondsToSelector:@selector(playbackDidFinishWithPlayer:)];
        _delegateFlags.didFailToLoadURL = [delegate respondsToSelector:@selector(player:didFailToLoadURL:)];
    }
}

- (BOOL)isPlaying {
    return self.player != nil && self.player.rate != 0.f;
}

- (void)setVideoGravity:(NGMoviePlayerVideoGravity)videoGravity {
    self.playerView.playerLayer.videoGravity = NGAVLayerVideoGravityFromNGMoviePlayerVideoGravity(videoGravity);
}

- (NGMoviePlayerVideoGravity)videoGravity {
    return NGMoviePlayerVideoGravityFromAVLayerVideoGravity(self.playerView.playerLayer.videoGravity);
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {
    CMTime time = CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC);
    
    // completion handler only supported in iOS 5
    if ([self.player respondsToSelector:@selector(seekToTime:completionHandler:)]) {
        [self.player seekToTime:time
              completionHandler:^(BOOL finished) {
                  if (finished) {
                      [self.playerView updateWithCurrentTime:self.currentTime duration:self.duration];
                  }
              }];
    } else {
        [self.player seekToTime:time];
    }
}

- (NSTimeInterval)currentTime {
    return CMTimeGetSeconds(self.player.currentTime);
}

- (NSTimeInterval)duration {
    return CMTimeGetSeconds(self.CMDuration);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - KVO
////////////////////////////////////////////////////////////////////////

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &playerItemStatusContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
        [self.playerView updateWithPlaybackStatus:self.playing];
        
        switch (status) {
            case AVPlayerStatusUnknown: {
                [self stopObservingPlayerTimeChanges];
                [self.playerView updateWithCurrentTime:self.currentTime duration:self.duration];
                // TODO: Disable buttons & scrubber
                break;
            }
                
            case AVPlayerStatusReadyToPlay: {
                // TODO: Enable buttons & scrubber
                if (!self.scrubbing) {
                    [self play];
                }
                
                break;
            }
                
            case AVPlayerStatusFailed: {
                [self stopObservingPlayerTimeChanges];
                [self.playerView updateWithCurrentTime:self.currentTime duration:self.duration];
                // TODO: Disable buttons & scrubber
                break;
            }
        }
        
        if (_delegateFlags.didChangeStatus) {
            [self.delegate player:self didChangeStatus:status];
        }
    } 
    
    else if (context == &playerItemDurationContext) {
        [self.playerView updateWithCurrentTime:self.currentTime duration:self.duration];
    } 
    
    else if (context == &playerCurrentItemContext) {
        AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
        
        if (newPlayerItem == (id)[NSNull null]) {
            [self stopObservingPlayerTimeChanges];
            // TODO: Disable buttons & scrubber
        } else {
            [self.playerView updateWithPlaybackStatus:self.playing];
            [self startObservingPlayerTimeChanges];
        }
    } 
    
    else if (context == &playerRateContext) {
        [self.playerView updateWithPlaybackStatus:self.playing];
        
        if (_delegateFlags.didChangePlaybackRate) {
            [self.delegate player:self didChangePlaybackRate:self.player.rate];
        }
    } 
    
    else if (context == &playerAirPlayVideoActiveContext) {
        if ([self.player respondsToSelector:@selector(airPlayVideoActive)]) {
            BOOL airPlayVideoActive = self.player.airPlayVideoActive;
            
            if (airPlayVideoActive) {
                //[self addSubview:self.airPlayActiveView];
                //self.airPlayActiveView.frame = self.bounds;
            } else {
                //[self.airPlayActiveView removeFromSuperview];
            }
            
            if (_delegateFlags.didChangeAirPlay) {
                [self.delegate player:self didChangeAirPlayActive:airPlayVideoActive];
            }
        }
    } 
    
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Notifications
////////////////////////////////////////////////////////////////////////

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification {
    [self.player pause];
    _seekToZeroBeforePlay = YES;
    [self.playerView setControlsVisible:YES animated:YES];
    
    if (_delegateFlags.didFinishPlayback) {
        [self.delegate playbackDidFinishWithPlayer:self];
    }
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Scrubbing
////////////////////////////////////////////////////////////////////////

- (void)beginScrubbing {
    [self stopObservingPlayerTimeChanges];
    
    _rateToRestoreAfterScrubbing = self.player.rate;
    self.player.rate = 0.f;
    self.scrubbing = YES;
}

- (void)endScrubbing {
    self.scrubbing = NO;
    self.player.rate = _rateToRestoreAfterScrubbing;
    _rateToRestoreAfterScrubbing = 0.f;
    [self startObservingPlayerTimeChanges];
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////

- (CMTime)CMDuration {
    // Pefered in HTTP Live Streaming.
    if ([self.playerItem respondsToSelector:@selector(duration)] && // 4.3
        self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        if (CMTIME_IS_VALID(self.playerItem.duration))
            return self.playerItem.duration;
    }
    
    else if (CMTIME_IS_VALID(self.player.currentItem.asset.duration)) {
        return self.player.currentItem.asset.duration;
    }
    
    return kCMTimeInvalid;
}

- (void)doneLoadingAsset:(AVAsset *)asset withKeys:(NSArray *)keys {
    if (!asset.playable) {
        if (_delegateFlags.didFailToLoadURL) {
            [self.delegate player:self didFailToLoadURL:self.URL];
        }
        
        return;
    }
    
    // Check if all keys are OK
	for (NSString *key in keys) {
		NSError *error = nil;
		AVKeyValueStatus status = [asset statusOfValueForKey:key error:&error];
        
		if (status == AVKeyValueStatusFailed || status == AVKeyValueStatusCancelled) {
            if (_delegateFlags.didFailToLoadURL) {
                [self.delegate player:self didFailToLoadURL:self.URL];
            }
            
			return;
		}
	}
    
    // Remove observer from old playerItem and create new one
    if (self.playerItem) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        [self.playerItem removeObserver:self forKeyPath:@"duration"];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
    
    [self setPlayerItem:[AVPlayerItem playerItemWithAsset:asset]];
    
    // Observe status, ok -> play
    [self.playerItem addObserver:self
                      forKeyPath:@"status"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:&playerItemStatusContext];
    
    // Durationchange
    [self.playerItem addObserver:self
                      forKeyPath:@"duration"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:&playerItemDurationContext];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(playerItemDidPlayToEndTime:) 
                                                 name:AVPlayerItemDidPlayToEndTimeNotification 
                                               object:self.playerItem];
    
    _seekToZeroBeforePlay = YES;
    
    // Create the player
    if (!self.player) {
        [self setPlayer:[AVPlayer playerWithPlayerItem:self.playerItem]];
        
        // Observe currentItem, catch the -replaceCurrentItemWithPlayerItem:
        [self.player addObserver:self
                      forKeyPath:@"currentItem"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:&playerCurrentItemContext];
        
        // Observe rate, play/pause-button?
        [self.player addObserver:self
                      forKeyPath:@"rate"
                         options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                         context:&playerRateContext];
        
    }
    
    // New playerItem?
    if (self.player.currentItem != self.playerItem) {
        [self.player replaceCurrentItemWithPlayerItem:self.playerItem];
        [self.playerView updateWithPlaybackStatus:self.playing];
    }
}

- (void)startObservingPlayerTimeChanges {
    if (self.playerTimeObserver == nil) {
        __ng_weak NGMoviePlayer *weakSelf = self;
        self.playerTimeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(.5, NSEC_PER_SEC)
                                                                            queue:dispatch_get_main_queue()
                                                                       usingBlock:^(CMTime time) {
                                                                           __strong NGMoviePlayer *strongSelf = weakSelf;
                                                                           
                                                                           if (strongSelf != nil) {
                                                                               if (CMTIME_IS_VALID(strongSelf.player.currentTime) && CMTIME_IS_VALID(strongSelf.duration)) {
                                                                                   [strongSelf.playerView updateWithCurrentTime:strongSelf.currentTime duration:strongSelf.duration];
                                                                               }
                                                                           }
                                                                       }];
    }
}

- (void)stopObservingPlayerTimeChanges {
    if (self.playerTimeObserver != nil) {
        [self.player removeTimeObserver:self.playerTimeObserver];
        self.playerTimeObserver = nil;
    }
}

@end
