#import "SEGAdobeIntegrationFactory.h"
#import "SEGAdobeIntegration.h"


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
    id<SEGADBMediaObjectFactory> ADBMediaObjectFactory = [[SEGRealADBMediaObjectFactory alloc] init];
    id<SEGADBMediaHeartbeatFactory> ADBMediaHeartbeatFactory = [[SEGRealADBMediaHeartbeatFactory alloc] init];
    id ADBMobileClass = [ADBMobile class];
    id ADBMediaHeartbeatClass = [ADBMediaHeartbeat class];
    id ADBMediaObjectClass = [ADBMediaObject class];
    id config = [[ADBMediaHeartbeatConfig alloc] init];

    return [[SEGAdobeIntegration alloc] initWithSettings:settings andADBMobile:ADBMobileClass andADBMediaHeartbeat:ADBMediaHeartbeatClass andADBMediaHeartbeatFactory:ADBMediaHeartbeatFactory andADBMediaHeartbeatConfig:config andADBMediaObject:ADBMediaObjectClass andADBMediaObjectFactory:ADBMediaObjectFactory];
}


- (NSString *)key
{
    return @"Adobe Analytics";
}

@end
