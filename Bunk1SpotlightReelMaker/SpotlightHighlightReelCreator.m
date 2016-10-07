//
//  SpotlightHighlightReelCreator.m
//  SpotlightHighlightReel
//
//  Created by Peter Kamm on 7/7/16.
//  Copyright © 2016 Spotlight. All rights reserved.
//

#import "SpotlightHighlightReelCreator.h"

#import <CoreMedia/CoreMedia.h>

#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

@interface SpotlightHighlightReelCreator()

@property (nonatomic, strong) AVAssetWriter *assetWriter;
@property (nonatomic, strong) AVAssetWriterInput *writerInput;
@property (nonatomic, strong) AVAssetWriterInputPixelBufferAdaptor *bufferAdapter;
@property (nonatomic, assign) CMTime frameTime;
@property (nonatomic, strong) NSDictionary *videoSettings;
@property (nonatomic, assign) BOOL isWritingPhotoVideo;

@end

@implementation SpotlightHighlightReelCreator

+ (SpotlightHighlightReelCreator *)sharedCreator {
    static dispatch_once_t pred;
    static SpotlightHighlightReelCreator *sharedCreator = nil;
    dispatch_once(&pred,^{
        sharedCreator = [[SpotlightHighlightReelCreator alloc] init];
        sharedCreator.isWritingPhotoVideo = NO;
    });
    return sharedCreator;
}

- (void)createMontageWithMedia:(NSArray*)mediaArray shouldSave:(BOOL)shouldSave{
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Select your background music"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Cool Kids"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self createMontageWithMedia:mediaArray songTitle:@"DT_TheDuff_CoolKids_INST130" shouldSave:shouldSave];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Disney Funk"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self createMontageWithMedia:mediaArray songTitle:@"TB - Disney Funk 124bpm" shouldSave:shouldSave];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Every Single Night"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self createMontageWithMedia:mediaArray songTitle:@"DT_TheDUFF_EverySingleNight_INST_125" shouldSave:shouldSave];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Ready 2 Go"
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction * _Nonnull action) {
                                                [self createMontageWithMedia:mediaArray songTitle:@"DT_TheDuff_Ready2Go_128_INST" shouldSave:shouldSave];
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Cancel"
                                              style:UIAlertActionStyleCancel
                                            handler:nil]];
    [self.spotlightReelCreatorDelegate presentViewController:alert animated:YES completion:nil];
}


- (void)createMontageWithMedia:(NSArray*)mediaArray
                     songTitle:(NSString*)songTitle
                    shouldSave:(BOOL)shouldSave{
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND,0), ^{
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *myPathDocs =  [documentsDirectory stringByAppendingPathComponent:
                                 [NSString stringWithFormat:@"montage.mov"]];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        self.videoSettings = [self videoSettingsWithCodec:AVVideoCodecH264
                                                withWidth:1280
                                                andHeight:720];
        
        AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
        AVMutableCompositionTrack *track = [mixComposition
                                            addMutableTrackWithMediaType:AVMediaTypeVideo
                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        CMTime totalDuration = kCMTimeZero;
        NSError* error;
        AVURLAsset *asset;
        NSURL *fileURL;
        for (NSString *mediaPath in mediaArray) {

            if ([self isMovie:mediaPath]) {
                NSLog(@"attempt...");
                
                asset = [AVURLAsset URLAssetWithURL:[NSURL URLWithString:mediaPath]
                                            options:nil];
                if (asset && [[asset tracksWithMediaType:AVMediaTypeVideo] count] > 0 ) {
                    [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                   ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                    atTime:totalDuration
                                     error:&error];
                    totalDuration = CMTimeAdd(totalDuration, asset.duration);
                    NSLog(@"woo...");
                    
                } else {
                    continue;
                }
            } else {
                NSString *fileName = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"image.mov"];
                fileURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName]];
                [self initWritersWithUrlPath:fileURL];
                self.isWritingPhotoVideo = YES;
                UIImage* image = [UIImage imageWithContentsOfFile:mediaPath];
                [self createMovieFromImage:image];

                while (self.isWritingPhotoVideo) {
                    [NSThread sleepForTimeInterval:0.05];
                }
                asset = [AVURLAsset URLAssetWithURL:fileURL
                                            options:nil];
                [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                               ofTrack:[[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                                atTime:totalDuration
                                 error:&error];
                totalDuration = CMTimeAdd(totalDuration, asset.duration);
            }
            if (error) {
                [self.spotlightReelCreatorDelegate spotlightHighlightReelCreator:self didFailWithError:error];
            }
        }
        NSURL *audio_url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:songTitle ofType:@"mp3"]];
        AVURLAsset  *audioAsset = [[AVURLAsset alloc]initWithURL:audio_url options:nil];
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                            preferredTrackID:kCMPersistentTrackID_Invalid];
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, totalDuration)
                            ofTrack:[[audioAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        [manager removeItemAtPath:myPathDocs error:nil];
        
        NSMutableArray* instructions = [NSMutableArray array];
        
        AVMutableVideoCompositionInstruction *videoCompositionInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        videoCompositionInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, totalDuration);
        videoCompositionInstruction.layerInstructions = @[[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:track]];
        [instructions addObject:videoCompositionInstruction];
        
        AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
        mutableVideoComposition.instructions = instructions;
        mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
        mutableVideoComposition.renderSize = CGSizeMake(1280, 720);
        
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:mixComposition];
        playerItem.videoComposition = mutableVideoComposition;

        if (shouldSave) {
            AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:mixComposition presetName:AVAssetExportPresetHighestQuality];
            NSString *fileName2 = [NSString stringWithFormat:@"%@_%@", [[NSProcessInfo processInfo] globallyUniqueString], @"spotlight.mov"];
            NSURL *fileURL2 = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:fileName2]];
            session.outputURL = fileURL2;
            session.outputFileType = AVFileTypeQuickTimeMovie;
            [session exportAsynchronouslyWithCompletionHandler:^(void ){
                 NSLog(@"TADA!");
                 dispatch_async(dispatch_get_main_queue(), ^{
                     [self.spotlightReelCreatorDelegate spotlightHighlightReelCreator:self didFinishWithPlayerItem:playerItem savedUrl:fileURL2];
                 });
             }];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.spotlightReelCreatorDelegate spotlightHighlightReelCreator:self didFinishWithPlayerItem:playerItem savedUrl:nil];
            });
        }
    });
}

- (BOOL)isMovie:(NSString*)mediaName {
    CFStringRef fileExtension = (__bridge CFStringRef) [mediaName pathExtension];
    CFStringRef fileUTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension, NULL);
    BOOL answer = (UTTypeConformsTo(fileUTI, kUTTypeMovie));
    CFRelease(fileUTI);
    return answer;
}

- (void)createMovieFromImage:(UIImage *)image
{
    [self.assetWriter startWriting];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    dispatch_queue_t mediaInputQueue = dispatch_queue_create("mediaInputQueue", NULL);
    
    __block NSInteger i = 0;
    
    NSInteger frameNumber = 3;
    // This can prob be significantly more efficient
    [self.writerInput requestMediaDataWhenReadyOnQueue:mediaInputQueue
                                            usingBlock:^{
                                                while (YES){
                                                    if (i >= frameNumber) {
                                                        break;
                                                    }
                                                    if ([self.writerInput isReadyForMoreMediaData]) {
                                                        
                                                        CVPixelBufferRef sampleBuffer = [self newPixelBufferFromCGImage:[image CGImage]];
                                                        
                                                        if (sampleBuffer) {
                                                            if (i == 0) {
                                                                [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:kCMTimeZero];
                                                            }else{
                                                                CMTime lastTime = CMTimeMake(i-1, self.frameTime.timescale);
                                                                CMTime presentTime = CMTimeAdd(lastTime, self.frameTime);
                                                                [self.bufferAdapter appendPixelBuffer:sampleBuffer withPresentationTime:presentTime];
                                                            }
                                                            CFRelease(sampleBuffer);
                                                            i++;
                                                        }
                                                    }
                                                }
                                                
                                                [self.writerInput markAsFinished];
                                                [self.assetWriter finishWritingWithCompletionHandler:^{
                                                    dispatch_async(dispatch_get_main_queue(), ^{
                                                        self.isWritingPhotoVideo = NO;
                                                    });
                                                }];
                                                
                                                CVPixelBufferPoolRelease(self.bufferAdapter.pixelBufferPool);
                                            }];
}

- (CVPixelBufferRef)newPixelBufferFromCGImage:(CGImageRef)image
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    
    CVPixelBufferRef pxbuffer = NULL;
    
    CGFloat frameWidth = [[self.videoSettings objectForKey:AVVideoWidthKey] floatValue];
    CGFloat frameHeight = [[self.videoSettings objectForKey:AVVideoHeightKey] floatValue];
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                                          frameWidth,
                                          frameHeight,
                                          kCVPixelFormatType_32ARGB,
                                          (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameWidth,
                                                 frameHeight,
                                                 8,
                                                 4 * frameWidth,
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGSize imageSize = CGSizeMake(CGImageGetWidth(image),
                                  CGImageGetHeight(image));
    CGRect targetBounds = CGRectMake(0, 0, frameWidth, frameHeight);
    CGRect imageRect = AVMakeRectWithAspectRatioInsideRect( imageSize,
                                                           targetBounds);
    
    
    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextDrawImage(context, imageRect, image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

-(void)exportDidFinish:(AVAssetExportSession*)session {
    
    switch (session.status) {
        case AVAssetExportSessionStatusFailed:
            NSLog(@"Export Status %@", session.error);
            NSLog(@"failed");
            break;
            
        case AVAssetExportSessionStatusCancelled:
            NSLog(@"cancelled");
            break;
            
        case AVAssetExportSessionStatusCompleted:
            NSLog(@"complete");
            break;
            
        case AVAssetExportSessionStatusExporting:
            NSLog(@"exporting");
            break;
            
        case AVAssetExportSessionStatusUnknown:
            NSLog(@"unknown");
            break;
            
        case AVAssetExportSessionStatusWaiting:
            NSLog(@"waiting");
            break;
            
        default:
            break;
    }
}

- (void)initWritersWithUrlPath:(NSURL*)fileURL {
    NSError *error;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL
                                             fileType:AVFileTypeQuickTimeMovie
                                                error:&error];
    if (error) {
        NSLog(@"Error: %@", error.debugDescription);
        [self.spotlightReelCreatorDelegate spotlightHighlightReelCreator:self didFailWithError:error];
    }
    NSParameterAssert(self.assetWriter);
    
    self.writerInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                      outputSettings:self.videoSettings];
    NSParameterAssert(self.writerInput);
    NSParameterAssert([self.assetWriter canAddInput:self.writerInput]);
    
    [self.assetWriter addInput:self.writerInput];
    
    NSDictionary *bufferAttributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                      [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
    
    self.bufferAdapter = [[AVAssetWriterInputPixelBufferAdaptor alloc] initWithAssetWriterInput:self.writerInput sourcePixelBufferAttributes:bufferAttributes];
    self.frameTime = CMTimeMake(1, 1);
}

- (NSDictionary *)videoSettingsWithCodec:(NSString *)codec withWidth:(CGFloat)width andHeight:(CGFloat)height
{
    if ((int)width % 16 != 0 ) {
        NSLog(@"Warning: video settings width must be divisible by 16.");
    }
    
    NSDictionary *videoSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                    AVVideoWidthKey : [NSNumber numberWithInt:(int)width],
                                    AVVideoHeightKey : [NSNumber numberWithInt:(int)height]};
    
    return videoSettings;
}

@end
