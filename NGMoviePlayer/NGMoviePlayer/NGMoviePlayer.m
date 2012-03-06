#import "NGMoviePlayer.h"
#import "NGMoviePlayerView.h"

@interface NGMoviePlayer () {
    // flags for methods implemented in the delegate
    struct {
        unsigned int didChangeStatus:1;
        unsigned int didChangePlaybackRate:1;
		unsigned int didChangeAirPlay:1;
		unsigned int didFinishPlayback:1;
	} _delegateFlags;
}

@end

@implementation NGMoviePlayer

@synthesize playerView = _playerView;
@synthesize URL = _URL;
@synthesize delegate = _delegate;

////////////////////////////////////////////////////////////////////////
#pragma mark - Lifecycle
////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
#pragma mark - NGMoviePlayer Properties
////////////////////////////////////////////////////////////////////////

- (void)setURL:(NSURL *)URL {
    
}

- (void)setDelegate:(id<NGMoviePlayerDelegate>)delegate {
    if (delegate != _delegate) {
        _delegate = delegate;
        
        _delegateFlags.didChangeStatus = [delegate respondsToSelector:@selector(player:didChangeStatus:)];
        _delegateFlags.didChangePlaybackRate = [delegate respondsToSelector:@selector(player:didChangePlaybackRate:)];
        _delegateFlags.didChangeAirPlay = [delegate respondsToSelector:@selector(player:didChangeAirPlayActive:)];
        _delegateFlags.didFinishPlayback = [delegate respondsToSelector:@selector(playbackDidFinishWithPlayer:)];
    }
}

- (BOOL)isPlaying {
    
}

- (void)setVideoGravity:(NGMoviePlayerVideoGravity)videoGravity {
    self.playerView.playerLayer.videoGravity = NGAVLayerVideoGravityFromNGMoviePlayerVideoGravity(videoGravity);
}

- (NGMoviePlayerVideoGravity)videoGravity {
    return NGMoviePlayerVideoGravityFromAVLayerVideoGravity(self.playerView.playerLayer.videoGravity);
}

////////////////////////////////////////////////////////////////////////
#pragma mark - Private
////////////////////////////////////////////////////////////////////////


@end
