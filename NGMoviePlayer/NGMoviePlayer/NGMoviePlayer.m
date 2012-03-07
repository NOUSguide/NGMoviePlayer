#import "NGMoviePlayer.h"
#import "NGMoviePlayerView.h"


static char playerItemStatusContext;
static char playerItemDurationContext;
static char playerCurrentItemContext;
static char playerRateContext;

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
}

@property (nonatomic, strong) AVAsset *asset;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, readonly) CMTime CMDuration;

@property (nonatomic, strong, readwrite) AVPlayer *player;  // re-defined as read/write

// player is ready to play
- (void)doneLoadingAsset:(AVAsset *)asset withKeys:(NSArray *)keys;

- (void)playerItemDidPlayToEndTime:(NSNotification *)notification;

@end

@implementation NGMoviePlayer

@synthesize player = _player;
@synthesize playerView = _playerView;
@synthesize URL = _URL;
@synthesize delegate = _delegate;
@synthesize asset = _asset;
@synthesize playerItem = _playerItem;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

- (id)init {
    if ((self = [super init])) {
        _seekToZeroBeforePlay = YES;
    }
    
    return self;
}

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayer Properties
////////////////////////////////////////////////////////////////////////

- (void)setURL:(NSURL *)URL {
    if (_URL != URL) {
        [self willChangeValueForKey:@"URL"];
        _URL = URL;
        [self didChangeValueForKey:@"URL"];
        
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
    return self.player.rate != 0.f;
}

- (void)setVideoGravity:(NGMoviePlayerVideoGravity)videoGravity {
    self.playerView.playerLayer.videoGravity = NGAVLayerVideoGravityFromNGMoviePlayerVideoGravity(videoGravity);
}

- (NGMoviePlayerVideoGravity)videoGravity {
    return NGMoviePlayerVideoGravityFromAVLayerVideoGravity(self.playerView.playerLayer.videoGravity);
}

- (void)setCurrentTime:(NSTimeInterval)currentTime {
    CMTime time = CMTimeMakeWithSeconds(currentTime, NSEC_PER_SEC);
    
    [self.player seekToTime:time];
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
        
    } else if (context == &playerItemDurationContext) {
        
    } else if (context == &playerCurrentItemContext) {
        
    } else if (context == &playerRateContext) {
        
    } else {
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

@end
