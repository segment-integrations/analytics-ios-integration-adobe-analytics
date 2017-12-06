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
- (ADBMediaObject *_Nullable)createWithProperties:(NSDictionary *_Nullable)properties;
@end


@interface SEGRealADBMediaObjectFactory : NSObject <SEGADBMediaObjectFactory>
@end


@interface SEGAdobeIntegration : NSObject <SEGIntegration>
@property (nonatomic, strong, nonnull) NSDictionary *settings;
@property (nonatomic, strong) Class _Nullable ADBMobile;

@property (nonatomic, strong, nullable) ADBMediaHeartbeat *ADBMediaHeartbeat;
@property (nonatomic, strong, nullable) id<SEGADBMediaHeartbeatFactory> ADBMediaHeartbeatFactory;
@property (nonatomic, strong, nullable) ADBMediaHeartbeatConfig *config;

@property (nonatomic, strong, nullable) ADBMediaObject *mediaObject;
@property (nonatomic, strong, nullable) id<SEGADBMediaObjectFactory> ADBMediaObjectFactory;

- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings;
- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings andADBMobile:(id _Nullable)ADBMobile andADBMediaHeartbeatFactory:(id<SEGADBMediaHeartbeatFactory> _Nullable)ADBMediaHeartbeatFactory andADBMediaHeartbeatConfig:(ADBMediaHeartbeatConfig *_Nullable)config andADBMediaObjectFactory:(id<SEGADBMediaObjectFactory> _Nullable)ADBMediaObjectFactory;

@end
