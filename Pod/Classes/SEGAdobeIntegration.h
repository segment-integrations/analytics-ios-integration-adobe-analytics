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
@property (nonatomic, strong, nullable) SEGPlaybackDelegate *playbackDelegate;
/**
 * Quality of service object. This is created and updated upon receipt of a "Video Quality
 * Updated" event, which triggers createAndUpdateQosObject(Properties).
 */
@property (nonatomic, strong, nullable) ADBMediaObject *qosObject;
/**
 * The system time in millis at which the playhead is first set or updated. The playhead is
 * first set upon instantiation of the PlaybackDelegate. The value is updated whenever
 * updatePlayheadPosition is invoked.
 */
@property (nonatomic) long initialTime;
/** The current playhead position in seconds. */
@property (nonatomic) long playheadPosition;
/** The position of the playhead in seconds when the video was paused. */
@property (nonatomic) long pausedPlayheadPosition;
/** The system time in millis at which {@link #pausePlayhead} was invoked. */
@property (nonatomic) long pausedStartedTime;
/**
 * The updated playhead position - this variable is assigned to the value a customer passes as
 * properties.seekPosition in a "Video Playback Seek Completed" event or properties.position in
 * a "Video Content Started" event
 */
@property (nonatomic) long updatedPlayheadPosition;
/** The total time in seconds a video has been in a paused state during a video session. */
@property (nonatomic) long offset;
/** Whether the video playhead is in a paused state. */
@property (nonatomic) BOOL isPaused;

- (NSTimeInterval)getCurrentPlaybackTime;
- (void)updatePlayheadPosition:(long)playheadPosition;
- (void)resumePlayheadAfterSeeking;
- (void)unPausePlayhead;
- (void)pausePlayhead;
- (void)incrementPlayheadPosition;
- (instancetype _Nullable)initWithDelegate:(SEGPlaybackDelegate *_Nullable)playbackDelegate;
- (void)createAndUpdateQOSObject:(NSDictionary *_Nullable)properties;
@end

@protocol SEGPlaybackDelegateFactory <NSObject>
- (SEGPlaybackDelegate *_Nullable)createPlaybackDelegate;
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
