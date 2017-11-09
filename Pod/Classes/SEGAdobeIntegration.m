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
@end
