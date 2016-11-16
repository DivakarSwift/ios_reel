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
#include <sys/xattr.h>
#import <CommonCrypto/CommonDigest.h>

@interface ViewController ()

@property (strong, nonatomic) NSURL* lastAssetURL;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    AFHTTPRequestOperationManager* manager = [AFHTTPRequestOperationManager manager];
    
    [manager POST:@"https://bunk1.com/api/spotlight/sign-in"
       parameters:nil
constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        [formData appendPartWithFormData:[@"Spotlight" dataUsingEncoding:NSUTF8StringEncoding] name:@"username"];
        [formData appendPartWithFormData:[@"2p0111g41" dataUsingEncoding:NSUTF8StringEncoding] name:@"password"];
    } success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Success: %@", responseObject);
//        [self getVidURLsForUser:497693 camp:995 token:responseObject[@"token"] manager:manager completion:nil];
        [self makeGetUsersCallFromCampId:262 startUserId:118376 token:responseObject[@"token"] manager:manager];
 //       [self makeCampsCallWithToken:responseObject[@"token"] manager:manager];
//        [self createVidFromFile];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
}

- (void)makeCampsCallWithToken:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager {

    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    [manager GET:@"https://bunk1.com/api/spotlight/organization"
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"DID IT! %@",responseObject);
             [self makeGetUsersCallFromCampId:[responseObject[@"camps"][0][@"id"] intValue] startUserId:0 token:token manager:manager];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];
}

- (void)makeGetUsersCallFromCampId:(int)campId startUserId:(int)startUserId token:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager {
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    NSString* url = [NSString stringWithFormat:@"https://bunk1.com/api/spotlight/organization/%i/users", campId];
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Got %lu users to create vids for",[responseObject[@"users"] count]);
             NSArray* usersArray;
             if (startUserId != 0) {
                 for(int i = 0; i < [responseObject[@"users"] count]; i++){
                     if (startUserId == [responseObject[@"users"][i][@"id"] intValue]) {
                         usersArray = [responseObject[@"users"] subarrayWithRange:NSMakeRange(i, [responseObject[@"users"] count] - i)];
                     }
                 }
             }else{
                 usersArray = responseObject[@"users"];
             }
             [self getVidURLsForUsers:usersArray camp:campId token:token manager:manager completion:^{
                 
             }];
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];
}

- (void)createVidFromFile {
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"955" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    NSError *error;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
    }
    NSMutableArray* urlArray = [NSMutableArray array];
    for (NSDictionary* imageObject in json[@"photos"]) {
        [urlArray addObject:imageObject[@"url"]];
    }
    if ([urlArray count] > 0) {
        NSLog(@"good to make vid &*(");
    } else {
        NSLog(@"bad to make vid!@#");
    }
    if ([urlArray count] > 0) {
        [self makeVidWithURLs:urlArray campId:955 userId:497693 completion:^{
            [self makeSampleVidWithURLs:urlArray campId:955 userId:497693 completion:^{
               
            }];
        }];
    }
}

- (void)getVidURLsForUsers:(NSArray*)userArray camp:(int)campId token:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager completion:(void (^)(void))completion {
    if ([userArray count] == 0) return;
    int userId = [userArray[0][@"id"] intValue];
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    NSString* url = [NSString stringWithFormat:@"https://bunk1.com/api/spotlight/organization/%i/user/%i/favorites", campId, userId];
    NSLog(@"Asking for favorites for user %d\nOnly %lu videos left to go...",userId, (unsigned long)[userArray count]);
    
    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSLog(@"Got vid for ! %@",responseObject);
             NSMutableArray* urlArray = [NSMutableArray array];
             for (NSDictionary* imageObject in responseObject[@"photos"]) {
                 [urlArray addObject:imageObject[@"url"]];
             }
             if ([urlArray count] > 0) {
                 NSLog(@"good to make vid &*(");
             } else {
                 NSLog(@"bad to make vid!@#");
             }
             if ([urlArray count] > 0) {
                 [self makeVidWithURLs:urlArray campId:campId userId:userId completion:^{
                     [self makeSampleVidWithURLs:urlArray campId:campId userId:userId completion:^{
                             NSMutableArray* oneLessUserArray = [NSMutableArray arrayWithArray:userArray];
                             [oneLessUserArray removeObjectAtIndex:0];
                             [self getVidURLsForUsers:[NSArray arrayWithArray:oneLessUserArray] camp:campId token:token manager:manager completion:^{
                                   completion();
                             }];
                     }];
                 }];
             } else {
                 NSMutableArray* oneLessUserArray = [NSMutableArray arrayWithArray:userArray];
                 [oneLessUserArray removeObjectAtIndex:0];
                 [self getVidURLsForUsers:[NSArray arrayWithArray:oneLessUserArray] camp:campId token:token manager:manager completion:^{
                     completion();
                 }];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];
}

- (void)getVidURLsForUser:(int)userId camp:(int)campId token:(NSString*)token manager:(AFHTTPRequestOperationManager*)manager completion:(void (^)(void))completion {
    [manager.requestSerializer setValue:[NSString stringWithFormat:@"Token token=%@", token] forHTTPHeaderField:@"Authorization"];
    NSString* url = [NSString stringWithFormat:@"https://bunk1.com/spotlight/organization/%i/user/%i/favorites", campId, userId];
    NSLog(@"Asking for favorites for user %d",userId);

    [manager GET:url
      parameters:nil
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             NSMutableArray* urlArray = [NSMutableArray array];
             for (NSDictionary* imageObject in responseObject[@"photos"]) {
                 [urlArray addObject:imageObject[@"url"]];
             }
             if ([urlArray count] > 0) {
                 [self makeVidWithURLs:urlArray campId:campId userId:userId completion:^{
                     [self makeSampleVidWithURLs:urlArray campId:campId userId:userId completion:completion];
                 }];
             }
         }
         failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             // Handle failure communicating with your server
             NSLog(@"Client Token request failed.%@",operation.responseString);
             NSLog(@"error code %ld",(long)[operation.response statusCode]);
         }];

}
- (void)makeSampleVidWithURLs:(NSArray*)urlz campId:(int)campId userId:(int)userId completion:(void (^)(void))completion{
    
    NSMutableArray* urlArray = [urlz mutableCopy];
    [urlArray insertObject:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/end_org_%d.jpg",campId] atIndex:0];
    UIImage* image;
    NSURL* fileURL;
    NSMutableArray* AVURLAssets = [NSMutableArray array];//[NSMutableArray arrayWithObject:[AVURLAsset URLAssetWithURL:beginURL options:nil]];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    int i = 0;
    while(i < 6){
        NSString *fileName = [NSString stringWithFormat:@"%@_%@", [NSString stringWithFormat:@"%i",i], @"image.mov"];
        NSURL *fileURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
        [AVURLAssets addObject:[AVURLAsset URLAssetWithURL:fileURL options:nil]];
        i++;
    }
    
    image = [self getImageFromURL:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/preview_end.png"]];
    fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                                                                     duration:3
                                                                                         name:[NSString stringWithFormat:@"%lu",(unsigned long)[AVURLAssets count]]
                                                                                   completion:^{
                                                                                   }];
    [AVURLAssets addObject:[AVURLAsset URLAssetWithURL:fileURL options:nil]];
    NSMutableArray* finalMediaArrayPaths = [NSMutableArray array];

    for (int j = 0; j+1 < [AVURLAssets count]; j++) {
        if (j+2 == [AVURLAssets count]) {
            MovieTransitions* mov = [[MovieTransitions alloc] init];
            NSArray* doubleAssets = @[ AVURLAssets[j], AVURLAssets[j+1] ];
            [mov makeTheMovies:doubleAssets name:[NSString stringWithFormat:@"%i",j] ];
        }
        [finalMediaArrayPaths addObject: [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%i.mov", j]] absoluteString]];
    }

    __block NSString* sampleName = [self sha1:[NSString stringWithFormat:@"%d_2016_sample", userId]];
    [[SpotlightHighlightReelCreator sharedCreator] createMontageWithMedia:finalMediaArrayPaths songTitle:@"TPWW_InMyShoes_F1" shouldSave:YES savedFileName:sampleName completion:^{
//        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
////            NSURL* filename = [[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.mp4", sampleName]];
////            NSLog (@"Playing from : %@", filename.absoluteString);
////
////            AVPlayer *player = [AVPlayer playerWithURL:filename];
////            AVPlayerViewController *playerViewController = [AVPlayerViewController new];
////            playerViewController.player = player;
////            [playerViewController.player play];//Used to Play On start
////            [self presentViewController:playerViewController animated:YES completion:nil];
//            [self.view setBackgroundColor:[UIColor greenColor]];
//        });
        if (completion) completion();
    }];
    
    
}

- (void)makeVidWithURLs:(NSArray*)urlz campId:(int)campId userId:(int)userId completion:(void (^)(void))completion{
    
    NSMutableArray* urlArray = [urlz mutableCopy];
    [urlArray insertObject:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/end_org_%d.jpg",campId] atIndex:0];
    MovieTransitions* mov = [[MovieTransitions alloc] init];
    
    int i = 0;
    UIImage* image;
    NSURL* fileURL;
    NSMutableArray* AVURLAssets = [NSMutableArray array];//[NSMutableArray arrayWithObject:[AVURLAsset URLAssetWithURL:beginURL options:nil]];
    
    while(i < [urlArray count] && i < 43){
        image = [self getImageFromURL:urlArray[i]];
        fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                                                                         duration:3
                                                                                             name:[NSString stringWithFormat:@"%i",i]
                                                                                       completion:nil];
        [AVURLAssets addObject:[AVURLAsset URLAssetWithURL:fileURL options:nil]];
        i++;
    }

    image = [self getImageFromURL:[NSString stringWithFormat:@"https://s3.amazonaws.com/myspotlight/uploads/end_org_%d.jpg",campId]];
    fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
                                                                                     duration:3
                                                                                         name:[NSString stringWithFormat:@"%lu",(unsigned long)[AVURLAssets count]]
                                                                                   completion:nil];
    [AVURLAssets addObject:[AVURLAsset URLAssetWithURL:fileURL options:nil]];

    NSMutableArray* finalMediaArrayPaths = [NSMutableArray array];

    // create trans
    NSArray* doubleAssets;
    for (int j = 0; j+1 < [AVURLAssets count]; j++) {
        doubleAssets = @[ AVURLAssets[j], AVURLAssets[j+1] ];
        [mov makeTheMovies:doubleAssets name:[NSString stringWithFormat:@"%i",j] ];
        [finalMediaArrayPaths addObject: [[[[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject] URLByAppendingPathComponent:[NSString stringWithFormat:@"%i.mov", j]] absoluteString]];
    }
    NSString* reelName = [self sha1:[NSString stringWithFormat:@"%d_2016", userId]];
    [[SpotlightHighlightReelCreator sharedCreator] createMontageWithMedia:finalMediaArrayPaths songTitle:@"TPWW_InMyShoes_F1" shouldSave:YES savedFileName:reelName completion:^{
        
//                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//                    
//                    NSArray* cachePathArray = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
//                    NSString* cachePath = [cachePathArray lastObject];
//                    NSURL *filename = [NSURL fileURLWithPath:[cachePath stringByAppendingPathComponent:reelName]];
//
//                    
//                    NSLog (@"Playing from : %@", filename.absoluteString);
//        
//                    AVPlayer *player = [AVPlayer playerWithURL:filename];
//                    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
//                    playerViewController.player = player;
//                    [playerViewController.player play];//Used to Play On start
//                    [self presentViewController:playerViewController animated:YES completion:nil];
//                });
        if (completion) completion();
        
    }];
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
    UIImage* image = [UIImage imageWithData:data];
    NSURL* fileURL = [[SpotlightHighlightReelCreator sharedCreator] synchronouslyreateVideoFromImage:image
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
    NSError *error;
    NSData* data = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:fileURL] options:NSDataReadingUncached error:&error];
    
    if (error) {
        NSLog(@"DATA READ ERROR!!! %@", error);
    }
//    NSData * data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
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
