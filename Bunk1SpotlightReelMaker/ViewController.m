//
//  ViewController.m
//  Bunk1SpotlightReelMaker
//
//  Created by Peter Kamm on 9/14/16.
//  Copyright © 2016 Spotlight. All rights reserved.
//

#import "ViewController.h"
#import "SpotlightHighlightReelCreator.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "Bunk1SpotlightReelMaker-Swift.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "AFNetworking.h"
#import "AFNetworkActivityLogger.h"

#include <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

@interface ViewController ()

@property (strong, nonatomic) NSURL* lastAssetURL;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[AFNetworkActivityLogger sharedLogger] startLogging];
    [[AFNetworkActivityLogger sharedLogger] setLevel:DEBUG];

    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:@"http://rollcallstaging.com/api/spotlight/sign-in.json"
       parameters:nil
constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[@"Spotlight" dataUsingEncoding:NSUTF8StringEncoding] name:@"username"];
        [formData appendPartWithFormData:[@"2p0111g41" dataUsingEncoding:NSUTF8StringEncoding] name:@"password"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
        [self getVidURLsForUser:390234 camp:262 token:responseObject[@"token"] manager:manager];
//        [self makeGetUsersCallFromCampId:262 token:responseObject[@"token"] manager:manager];
       // [self makeCampsCallWithToken:responseObject[@"token"] manager:manager];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    

}

- (void)makeCampsCallWithToken:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager {
 //   manager.responseSerializer = [AFJSONResponseSerializer serializer];
 //   manager.requestSerializer = [AFJSONRequestSerializer serializer];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    [manager GET:@"http://secure.rollcallstaging.com/api/spotlight/organization"
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"DID IT! %@",responseObject);
             [self makeGetUsersCallFromCampId:[responseObject[@"camps"][0][@"id"] intValue] token:token manager:manager];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];
}

- (void)makeGetUsersCallFromCampId:(int)campId token:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager {
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    NSString* url = [NSString stringWithFormat:@"http://rollcallstaging.com/api/spotlight/organization/%i/users", campId];
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"DID IT! %@",responseObject);
             for (NSDictionary *user in responseObject[@"users"]) {
                 [self getVidURLsForUser:[user[@"id"] intValue] camp:campId token:token manager:manager];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];
}

- (void)getVidURLsForUser:(int)userId camp:(int)campId token:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager {
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    NSString* url = [NSString stringWithFormat:@"http://rollcallstaging.com/api/spotlight/organization/%i/user/%i/favorites", campId, userId];
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"DID IT! %@",responseObject);
             NSMutableArray* urlArray = [NSMutableArray array];
             for (NSDictionary* imageObject in responseObject[@"photos"]) {
                 [urlArray addObject:imageObject[@"url"]];
             }
             [self makeVidWithURLs:urlArray campId:campId userId:userId];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];

    
    
}

- (void)makeVidWithURLs:(NSArray*)urlArray campId:(int)campId userId:(int)userId {
    
        MovieTransitions* mov = [[MovieTransitions alloc] init];
    
//        NSArray* urlArray = @[ @"https://s3.amazonaws.com/myspotlight/uploads/begin.png",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102713/large_6c034cf67a.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102752/large_630a51c8cb.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102705/large_236c52b297.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102698/large_d2f55c9c1e.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102700/large_5e67da6426.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102708/large_aecfafec36.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102729/large_2430180ffd.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102699/large_0c2597200e.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102745/large_c215a16391.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102704/large_1ed671838f.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102682/large_8f892a328b.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102774/large_1ab79946a2.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102722/large_be28419d44.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102725/large_760a84b472.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102733/large_fcda18e000.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102739/large_ba2d895e76.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102765/large_53be0ea0e7.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102707/large_687b13d76f.jpg",
//                               @"https://cdn-uploads.rollcallstaging.com/organizations/staging-433/photo/image/6102679/large_3433e57f15.jpg",
//                               @"https://s3.amazonaws.com/myspotlight/uploads/end.png"
//                               ];
    
     //   NSURL* beginURL = [self createBeginVid];
    
//    NSMutableArray* urlArrayz = [NSMutableArray array];
//    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"LAintro" ofType:@"PNG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2354" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2361" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2368" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2369" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2380" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2383" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2386" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2387" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2400" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2401" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2404" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2405" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2408" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2409" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2412" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2414" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2425" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2431" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2438" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2441" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2442" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2446" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2448" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2450" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2451" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2452" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2453" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2456" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2458" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"IMG_2459" ofType:@"JPG"];
//    [urlArrayz addObject:path];
//    path = [[NSBundle mainBundle] pathForResource:@"LAoutro" ofType:@"PNG"];
//    [urlArrayz addObject:path];
    
    
                           
//    NSArray *urlArrayz = @[ @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/LAintro.PNG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2354.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2361.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2368.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2380.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2369.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2383.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2386.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2387.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2400.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2404.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2405.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2408.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2409.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2412.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2414.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2425.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2431.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2438.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2441.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2442.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2446.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2448.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2450.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2451.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2452.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2453.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2456.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2458.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/IMG_2459.JPG",
//                            @"https://s3.amazonaws.com/myspotlight/uploads/Port+Washington+Astros/LAoutro.PNG"
//                            ];
        int i = 0;
        UIImage* image;
        NSURL* fileURL;
        NSMutableArray* AVURLAssets = [NSMutableArray array];//[NSMutableArray arrayWithObject:[AVURLAsset URLAssetWithURL:beginURL options:nil]];
        __block bool shouldContinue = NO;
        while(i < [urlArray count]){
            shouldContinue = NO;
            image = [self getImageFromURL:urlArray[i]];
            fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                         duration:3
                                             name:[NSString stringWithFormat:@"%i",i]
                                       completion:^{
                                           shouldContinue = YES;
                                       }];
            [AVURLAssets addObject:[AVURLAsset URLAssetWithURL:fileURL options:nil]];
            if (!shouldContinue){
                 [NSThread sleepForTimeInterval:0.05];
             }
            NSLog(@"finished a vid");
            i++;
           // [NSThread sleepForTimeInterval:1.0];
    
        }
    [AVURLAssets insertObject:[AVAsset assetWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/org_%d.jpg",campId]]] atIndex:0];
    
    NSMutableArray* sampleAVURLAssets = [[AVURLAssets subarrayWithRange:NSMakeRange(0,5)] mutableCopy];
    
    [sampleAVURLAssets addObject:[AVAsset assetWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/end_org_%d.jpg",campId]]]];
    [AVURLAssets addObject:[AVAsset assetWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/end_org_%d.jpg",campId]]]];
    
    NSMutableArray* finalMediaArrayPaths = [NSMutableArray array];
    NSArray* doubleAssets;
    for (int i = 0; i+1 < [AVURLAssets count]; i++) {
        doubleAssets = @[ AVURLAssets[i], AVURLAssets[i+1] ];
        [mov makeTheMovies:doubleAssets name:[NSString stringWithFormat:@"%i",i] ];
        [finalMediaArrayPaths addObject: [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%i.mov", i]] absoluteString]];
    }
    
    NSString* sampleName = [self sha1:[NSString stringWithFormat:@"%d_2016_sample", userId]];
    NSString* reelName = [self sha1:[NSString stringWithFormat:@"%d_2016_sample", userId]];

    [[SpotlightHighlightReelCreator sharedCreator] createMontageWithMedia:finalMediaArrayPaths songTitle:@"TPWW_InMyShoes_F1.mp3" shouldSave:YES savedFileName:reelName];
    [[SpotlightHighlightReelCreator sharedCreator] createMontageWithMedia:sampleAVURLAssets songTitle:@"TPWW_InMyShoes_F1.mp3" shouldSave:YES savedFileName:sampleName];
}

-(NSURL*)createEndVid {
    __block bool shouldContinue = NO;
    NSString *fileLocation = [[NSBundle mainBundle] pathForResource:@"e" ofType:@"png"];
    NSError *error;
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fileLocation error:&error];
    if (!success) {
        NSLog(@"Error removing file at path: %@", error.localizedDescription);
    }
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileLocation]];
    UIImage* image = [UIImage imageWithData:data];    NSURL* fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                                                                            duration:4
                                                                                                name:@"d"
                                                                                          completion:^{
                                                                                              shouldContinue = YES;
                                                                                          }];
    if (!shouldContinue){
        [NSThread sleepForTimeInterval:0.05];
    }
    return fileURL;
}

-(NSURL*)createBeginVid {
    __block bool shouldContinue = NO;
    NSString *fileLocation = [[NSBundle mainBundle] pathForResource:@"b" ofType:@"png"];
    NSError *error;
    
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:fileLocation error:&error];
    if (!success) {
        NSLog(@"Error removing file at path: %@", error.localizedDescription);
    }
    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileLocation]];
    UIImage* image = [UIImage imageWithData:data];
    //UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    //iv.frame = self.view.frame;
    //[self.view addSubview:iv];
    NSURL* fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                                                                            duration:4
                                                                                                name:@"bc"
                                                                                          completion:^{
                                                                                              shouldContinue = YES;
                                                                                          }];
    if (!shouldContinue){
        [NSThread sleepForTimeInterval:0.05];
    }
    return fileURL;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //filePath may be from the Bundle or from the Saved file Directory, it is just the path for the video
//    AVPlayer *player = [AVPlayer playerWithURL:self.lastAssetURL];
//    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
//    playerViewController.player = player;
//    //[playerViewController.player play];//Used to Play On start
//    [self presentViewController:playerViewController animated:YES completion:nil];
}

-(UIImage *) getImageFromURL:(NSString *)fileURL {
    UIImage * result;
//    NSData * data = [NSData dataWithContentsOfFile:fileURL];

    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    result = [UIImage imageWithData:data];
    
    return result;
}

- (AVURLAsset*)getAVAssetFromRemoteUrl:(NSURL*)url index:(int)index
{

    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *fileURL = [[tmpDirURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%i", index]] URLByAppendingPathExtension:@"mp4"];
    NSLog(@"fileURL: %@", [fileURL path]);
    
    NSData *urlData = [NSData dataWithContentsOfURL:url];
    [urlData writeToURL:fileURL options:NSAtomicWrite error:nil];
    
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    return asset;
}

- (AVURLAsset*)getAVAssetFromLocalUrl:(NSURL*)url
{
    AVURLAsset* asset = [AVURLAsset URLAssetWithURL:url options:nil];
    return asset;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//   [NSThread sleepForTimeInterval:2.5];

//    AVMutableComposition* composition= [[AVMutableComposition alloc] init];
//    [mov makeTheMovies:AVURLAssets name:@"1" ];


//    AVMutableComposition* composition= [[AVMutableComposition alloc] init];
//    [mov makeTheMovies:composition movieAssets:@[ AVURLAssets[0], AVURLAssets[1] ] name:@"1" ];
//    NSArray* doubleAssets;
//    for (int i = 2; i < [urlArray count]; i++) {
//        NSURL* assetLocation = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%i.mov", i - 1]];
//        NSLog(@"Picking up created vid at %@", assetLocation.absoluteString);
//        AVURLAsset *asset = [self getAVAssetFromLocalUrl:assetLocation];
//        doubleAssets = @[ asset, AVURLAssets[i] ];
//        composition  = [[AVMutableComposition alloc] init];
//        [mov makeTheMovies:composition movieAssets:doubleAssets name:[NSString stringWithFormat:@"%i",i] ];
//        self.lastAssetURL = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%i.mov", i]];
//    }
//

-(NSString*)sha1:(NSString*)string
{
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data.bytes, (int)data.length, digest);
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
        [output appendFormat:@"%02x", digest[i]];
    return output;
}


@end
