//
//  SEGAdobeHeartbeat.m
//  AdobeMobileSDK
//
//  Created by ladan nasserian on 12/2/17.
//

#import "SEGAdobeHeartbeat.h"
#import <Analytics/SEGAnalytics.h>

@interface VideoAnalyticsProvider : NSObject <ADBMediaHeartbeatDelegate>

id<ADBMediaHeartbeatDelegate> playBackDelegate();

@end

///-------------------------
/// @name Media Heartbeat Initialization
///-------------------------

ADBMediaHeartbeatConfig *createConfig(SEGTrackPayload *payload, NSDictionary *settings)
{
    NSDictionary *app = payload.context[@"app"];
    NSDictionary *properties = payload.properties;
    NSDictionary *options = payload.integrations[@"Adobe Analytics"];
    
    ADBMediaHeartbeatConfig *config = [[ADBMediaHeartbeatConfig alloc] init];
    bool sslEnabled = @NO;
    if (settings[@"ssl"]) {
        sslEnabled = @YES;
    }
    
    bool debugEnabled = @NO;
    if (options[@"debug"]) {
        debugEnabled = @YES;
    }
    
    config.trackingServer = settings[@"heartbeatTrackingServer"];
    config.channel = properties[@"channel"];
    config.ovp = options[@"ovp_name"];
    config.appVersion = app[@"version"];
    config.playerName = properties[@"video_player"];
    config.ssl = sslEnabled;
    config.debugLogging = debugEnabled;
    
    return config;
}

ADBMediaHeartbeat *initializeMediaHeartbeat(ADBMediaHeartbeatConfig *config, id<ADBMediaHeartbeatDelegate> playerDelegate)
{
    //Replace <ADBMediaHeartBeatDelegate> with your delegate instance
    ADBMediaHeartbeat *mediaHeartbeat = [[ADBMediaHeartbeat alloc] initWithDelegate:
                       playerDelegate config:config];
    return mediaHeartbeat;
}

void videoPlaybackStarted(SEGTrackPayload *payload, NSDictionary *settings)
{
    ADBMediaHeartbeatConfig *config = createConfig(payload, settings);
    initializeMediaHeartbeat(config, playBackDelegate());
}

