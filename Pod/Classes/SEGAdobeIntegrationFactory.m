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
    return [[SEGAdobeIntegration alloc] initWithSettings:settings];
}


- (NSString *)key
{
    return @"Adobe Analytics";
}

@end
