Pod::Spec.new do |s|
  s.platform     = :ios, '8.0'
  s.name         = 'NGMoviePlayer'
  s.version      = '1.0.2'
  s.license      = 'MIT'
  s.summary      = 'A custom movie player control for iOS.'
  s.description  = 'A custom (and customizable) movie player control for iOS.'
  s.homepage     = "http://nousdigital.com/"
  s.source       = { :git => 'https://github.com/NOUSguide/NGMoviePlayer.git', :tag => '1.0.2' }
  s.source_files = 'NGMoviePlayer/*/*.{h,m}'
  s.resource     = 'NGMoviePlayer/Resources/NGMoviePlayer.bundle'
  s.requires_arc = true
  s.frameworks   = 'Foundation', 'MediaPlayer', 'AVFoundation', 'CoreMedia', 'QuartzCore', 'UIKit'
  s.authors      = { 'PocketScience GmbH' => 'office@pocketscience.com' }

  s.prefix_header_contents = '
#ifdef __OBJC__
    #import <Foundation/Foundation.h>
    #import <UIKit/UIKit.h>
    #import <AVFoundation/AVFoundation.h>
    #import <QuartzCore/QuartzCore.h>
    #import <MediaPlayer/MediaPlayer.h>
#endif

#define kNGFadeDuration                     0.33
    '
  s.dependency 'NGVolumeControlKit', '~> 1.0'
  s.dependency 'PSPushPopPressView', '~> 1.0'
end
