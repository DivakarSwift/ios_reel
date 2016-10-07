//
//  SpotlightHighlightReelCreator.h
//  SpotlightHighlightReel
//
//  Created by Peter Kamm on 7/7/16.
//  Copyright © 2016 Spotlight. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

@class SpotlightHighlightReelCreator;

@protocol SpotlightReelCreatorDelegateProtocol <NSObject>

- (void)spotlightHighlightReelCreator:(SpotlightHighlightReelCreator*)creator didFinishWithPlayerItem:(AVPlayerItem*)playerItem savedUrl:(NSURL*)url;
- (void)spotlightHighlightReelCreator:(SpotlightHighlightReelCreator*)creator didFailWithError:(NSError*)error;

@end

@interface SpotlightHighlightReelCreator : NSObject

@property(weak, nonatomic) UIViewController<SpotlightReelCreatorDelegateProtocol>* spotlightReelCreatorDelegate;

+ (SpotlightHighlightReelCreator *)sharedCreator;
- (void)createMontageWithMedia:(NSArray*)mediaArray shouldSave:(BOOL)shouldSave;

@end
