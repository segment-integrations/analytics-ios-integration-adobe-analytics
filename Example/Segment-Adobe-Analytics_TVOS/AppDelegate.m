//
//  AppDelegate.m
//  Segment-Adobe-Analytics_TVOS
//
//  Created by Brienne McNally on 3/23/20.
//  Copyright © 2020 ladanazita. All rights reserved.
//

#import "AppDelegate.h"
#import "SEGAdobeIntegrationFactory.h"
#if defined(__has_include) && __has_include(<Analytics/SEGAnalytics.h>)
#import <Analytics/SEGAnalytics.h>
#else
#import <Segment/SEGAnalytics.h>
#endif

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    SEGAnalyticsConfiguration *config = [SEGAnalyticsConfiguration configurationWithWriteKey:@"YOUR_WRITE_KEY_HERE"];

    [config use:[SEGAdobeIntegrationFactory instance]];
    [SEGAnalytics setupWithConfiguration:config];
    [[SEGAnalytics sharedAnalytics] track:@"Video Playback Started"
                              properties:@{
                                  @"channel": @"SegTest",
                                  @"video_player": @"Segment",
                                  @"title": @"Test Show",
                                  @"content_asset_id": @"132421",
                                  @"total_length": @"300",
                                  @"livestream": @false,
                              }
                               options:@{
                                  @"context":@{}}
    ];
    [[SEGAnalytics sharedAnalytics] track:@"Video Content Started"
                           properties: @{ @"full_episode": @true }
                              options: @{
                                @"integrations": @{}
                            }];

    [[SEGAnalytics sharedAnalytics] flush];
    [SEGAnalytics debug:YES];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


@end
