#import "SEGAdobeIntegrationFactory.h"
#import "SEGAdobeIntegration.h"
#import <AdobeVideoHeartbeatSDK/ADBMediaHeartbeatConfig.h>


@implementation SEGAdobeIntegrationFactory

+ (instancetype)instance
{
    static dispatch_once_t once;
    static SEGAdobeIntegrationFactory *sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    return self;
}


- (id<SEGIntegration>)createWithSettings:(NSDictionary *)settings forAnalytics:(nonnull SEGAnalytics *)analytics
{
    id<SEGADBMediaObjectFactory> mediaObjectFactory = [[SEGRealADBMediaObjectFactory alloc] init];
    id<SEGADBMediaHeartbeatFactory> mediaHeartbeatFactory = [[SEGRealADBMediaHeartbeatFactory alloc] init];
    id adobeMobile = [ADBMobile class];
    id config = [[ADBMediaHeartbeatConfig alloc] init];
    id<SEGPlaybackDelegateFactory> delegateFactory = [[SEGRealPlaybackDelegateFactory alloc] init];

    return [[SEGAdobeIntegration alloc] initWithSettings:settings adobe:adobeMobile andMediaHeartbeatFactory:mediaHeartbeatFactory andMediaHeartbeatConfig:config andMediaObjectFactory:mediaObjectFactory andPlaybackDelegateFactory:delegateFactory];
}


- (NSString *)key
{
    return @"Adobe Analytics";
}

@end
