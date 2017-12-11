//
//  SEGAdobeIntegration.h
//
//
//  Created by ladan nasserian on 11/8/17.
//
//

#import <Foundation/Foundation.h>
#import <Analytics/SEGIntegration.h>
#import <AdobeMobileSDK/ADBMobile.h>
#import "ADBMediaHeartbeat.h"
#import "ADBMediaHeartbeatConfig.h"

@protocol SEGADBMediaHeartbeatFactory <NSObject>
- (ADBMediaHeartbeat *_Nullable)createWithDelegate:(id _Nullable)delegate andConfig:(ADBMediaHeartbeatConfig *_Nonnull)config;
@end


@interface SEGRealADBMediaHeartbeatFactory : NSObject <SEGADBMediaHeartbeatFactory>
@end

@protocol SEGADBMediaObjectFactory <NSObject>
- (ADBMediaObject *_Nullable)createWithProperties:(NSDictionary *_Nullable)properties andEventType:(NSString *_Nullable)eventType;
@end


@interface SEGRealADBMediaObjectFactory : NSObject <SEGADBMediaObjectFactory>
@end


@interface VideoAnalyticsProvider : NSObject <ADBMediaHeartbeatDelegate>
@end


@interface SEGAdobeIntegration : NSObject <SEGIntegration>
@property (nonatomic, strong, nonnull) NSDictionary *settings;
@property (nonatomic, strong) Class _Nullable adobeMobile;

@property (nonatomic, strong, nullable) ADBMediaHeartbeat *mediaHeartbeat;
@property (nonatomic, strong, nullable) id<SEGADBMediaHeartbeatFactory> heartbeatFactory;
@property (nonatomic, strong, nullable) ADBMediaHeartbeatConfig *config;

@property (nonatomic, strong, nullable) ADBMediaObject *mediaObject;
@property (nonatomic, strong, nullable) id<SEGADBMediaObjectFactory> objectFactory;

@property (nonatomic, strong, nullable) VideoAnalyticsProvider *playbackDelegate;

- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings adobe:(id _Nullable)adobeMobile andMediaHeartbeatFactory:(id<SEGADBMediaHeartbeatFactory> _Nullable)heartbeatFactory andMediaHeartbeatConfig:(ADBMediaHeartbeatConfig *_Nullable)config andMediaObjectFactory:(id<SEGADBMediaObjectFactory> _Nullable)objectFactory;

@end
