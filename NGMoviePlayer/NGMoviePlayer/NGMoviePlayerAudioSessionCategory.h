//
//  NGMoviePlayerAudioSessionCategory.h
//  NGMoviePlayer
//
//  Created by Tretter Matthias on 29.03.12.
//  Copyright (c) 2012 NOUS Wissensmanagement GmbH. All rights reserved.
//

typedef enum {
    NGMoviePlayerAudioSessionCategoryPlayback = 0,  // default
    NGMoviePlayerAudioSessionCategoryAmbient,
    NGMoviePlayerAudioSessionCategorySoloAmbient,
    NGMoviePlayerAudioSessionCategoryRecord,
    NGMoviePlayerAudioSessionCategoryPlayAndRecord,
    NGMoviePlayerAudioSessionCategoryAudioProcessing,
} NGMoviePlayerAudioSessionCategory;


NS_INLINE NSString* NGAVAudioSessionCategoryFromNGMoviePlayerAudioSessionCategory(NGMoviePlayerAudioSessionCategory audioSessionCategory) {
    switch (audioSessionCategory) {    
        case NGMoviePlayerAudioSessionCategoryAmbient: {
            return AVAudioSessionCategoryAmbient;
        }
            
        case NGMoviePlayerAudioSessionCategorySoloAmbient: {
            return AVAudioSessionCategorySoloAmbient;
        }
            
        case NGMoviePlayerAudioSessionCategoryRecord: {
            return AVAudioSessionCategoryRecord;
        }
            
        case NGMoviePlayerAudioSessionCategoryPlayAndRecord: {
            return AVAudioSessionCategoryPlayAndRecord;
        }
            
        case NGMoviePlayerAudioSessionCategoryAudioProcessing: {
            return AVAudioSessionCategoryAudioProcessing;
        }
            
        default:
        case NGMoviePlayerAudioSessionCategoryPlayback: {
            return AVAudioSessionCategoryPlayback;
        }
    }
}