//
//  SEGAdobeIntegration.m
//  Pods
//
//  Created by ladan nasserian on 11/8/17.
//
//

#import "SEGAdobeIntegration.h"
#import <Analytics/SEGIntegration.h>
#import <Analytics/SEGAnalyticsUtils.h>
#import <Analytics/SEGAnalytics.h>


@implementation SEGAdobeIntegration

#pragma mark - Initialization

- (instancetype)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        self.settings = settings;
        self.ADBMobile = [ADBMobile class];
    }

    return self;
}

- (instancetype)initWithSettings:(NSDictionary *)settings andADBMobile:(id _Nullable)ADBMobile
{
    if (self = [super init]) {
        self.settings = settings;
        self.ADBMobile = ADBMobile;
    }
    return self;
}

- (void)reset
{
    [self.ADBMobile trackingClearCurrentBeacon];
    SEGLog(@"[ADBMobile trackingClearCurrentBeacon];");
}

- (void)flush
{
    // Choosing to use `trackingSendQueuedHits` in lieu of
    // `trackingClearQueue` because the latter also
    // removes the queued events from the database
    [self.ADBMobile trackingSendQueuedHits];
    SEGLog(@"ADBMobile trackingSendQueuedHits");
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    if (!payload.userId) return;
    [self.ADBMobile setUserIdentifier:payload.userId];
    SEGLog(@"[ADBMobile setUserIdentifier:%@]", payload.userId);
}

- (void)track:(SEGTrackPayload *)payload
{
    if ([payload.properties count] > 0 && [self.settings[@"contextValues"] count] > 0) {
        NSMutableDictionary *data = [self mapcontextValues:payload.properties];
        [self.ADBMobile trackAction:payload.event data:data];
        return;
    }
    [self.ADBMobile trackAction:payload.event data:nil];
}

- (NSMutableDictionary *)mapcontextValues:(NSDictionary *)properties
{
    NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:0];
    NSDictionary *contextValues = self.settings[@"contextValues"];
    for (NSString *key in contextValues) {
        [data setObject:properties[key] forKey:contextValues[key]];
    }
    return data;
}

@end
