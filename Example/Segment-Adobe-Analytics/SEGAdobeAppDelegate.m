//
//  SEGAdobeAppDelegate.m
//  Segment-Adobe-Analytics
//
//  Created by ladanazita on 11/07/2017.
//  Copyright (c) 2017 ladanazita. All rights reserved.
//

#import "SEGAdobeAppDelegate.h"
#import "SEGAdobeIntegrationFactory.h"
#if defined(__has_include) && __has_include(<Analytics/Analytics.h>)
#import <Analytics/SEGAnalytics.h>
#else
#import <Segment/SEGAnalytics.h>
#endif


@implementation SEGAdobeAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    // Override point for customization after application launch.
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
