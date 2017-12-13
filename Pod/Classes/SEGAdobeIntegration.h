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


@interface SEGPlaybackDelegate : NSObject <ADBMediaHeartbeatDelegate>
/**
 * Quality of service object. This is created and updated upon receipt of a "Video Quality
 * Updated" event, which triggers createAndUpdateQosObject(Properties).
 */
@property (nonatomic, strong, nullable) ADBMediaObject *qosObject;
/**
 * The system time in seconds at which the playheadPosition has been recorded.
 */
@property (nonatomic) long playheadPositionTime;
/** The current playhead position in seconds. */
@property (nonatomic) long playheadPosition;
/** Whether the video playhead is in a paused state. */
@property (nonatomic) BOOL isPaused;

- (instancetype _Nullable)initWithPlayheadPosition:(long)playheadPosition;
- (NSTimeInterval)getCurrentPlaybackTime;
- (void)pausePlayhead;
- (void)unPausePlayhead;
- (void)updatePlayheadPosition:(long)playheadPosition;
- (void)createAndUpdateQOSObject:(NSDictionary *_Nullable)properties;
@end

@protocol SEGPlaybackDelegateFactory <NSObject>
- (SEGPlaybackDelegate *_Nullable)createPlaybackDelegateWithPosition:(long)playheadPosition;
@end


@interface SEGRealPlaybackDelegateFactory : NSObject <SEGPlaybackDelegateFactory>
@property (nonatomic, strong, nullable) SEGPlaybackDelegate *playbackDelegate;
@end


@interface SEGAdobeIntegration : NSObject <SEGIntegration>
@property (nonatomic, strong, nonnull) NSDictionary *settings;
@property (nonatomic, strong) Class _Nullable adobeMobile;

@property (nonatomic, strong, nullable) ADBMediaHeartbeat *mediaHeartbeat;
@property (nonatomic, strong, nullable) id<SEGADBMediaHeartbeatFactory> heartbeatFactory;
@property (nonatomic, strong, nullable) ADBMediaHeartbeatConfig *config;

@property (nonatomic, strong, nullable) ADBMediaObject *mediaObject;
@property (nonatomic, strong, nullable) id<SEGADBMediaObjectFactory> objectFactory;

@property (nonatomic, strong, nullable) SEGPlaybackDelegate *playbackDelegate;
@property (nonatomic, strong, nullable) id<SEGPlaybackDelegateFactory> delegateFactory;

- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings adobe:(id _Nullable)adobeMobile andMediaHeartbeatFactory:(id<SEGADBMediaHeartbeatFactory> _Nullable)heartbeatFactory andMediaHeartbeatConfig:(ADBMediaHeartbeatConfig *_Nullable)config andMediaObjectFactory:(id<SEGADBMediaObjectFactory> _Nullable)objectFactory andPlaybackDelegateFactory:(id<SEGPlaybackDelegateFactory> _Nullable)delegateFactory;

@end
