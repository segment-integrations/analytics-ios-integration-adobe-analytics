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
#import "ADBMediaHeartbeat.h"


@implementation SEGPlaybackDelegate

- (instancetype)initWithDelegate:(SEGPlaybackDelegate *)playbackDelegate
{
    self.playbackDelegate = playbackDelegate;
    if (self = [super init]) {
        self.initialTime = CFAbsoluteTimeGetCurrent();
    }
    return self;
}


/**
 * Adobe invokes this method once per second to resolve the current position of the video
 * playhead. Unless paused, this method increments the value of playheadPosition by one
 * every second by calling incrementPlayheadPosition
 */
- (NSTimeInterval)getCurrentPlaybackTime
{
    if (!self.isPaused) {
        [self.playbackDelegate incrementPlayheadPosition];
        return self.playheadPosition;
    }
    return self.pausedPlayheadPosition;
}

/**
 * getCurrentPlaybackTime invokes this method once per second to resolve the current
 * location of the video playhead:
 *
 * updatedPlayheadPosition + (currentSystemTime - videoSessionStartTime) - offset
 *
 * updatedPlayheadPosition represents a user-specified position of the playhead.
 * This is useful for updating the playhead position after a "Video Content Started" or "Video
 * Playback Seek Completed" event. The user must provide the updated playhead position in order
 * for this method to update the playhead position here properly.
 */

- (void)incrementPlayheadPosition
{
    self.playheadPosition = self.updatedPlayheadPosition + ((CFAbsoluteTimeGetCurrent() - self.initialTime) / 1000) - self.offset;
}

/**
 * Stores the current playhead position in pausedPlayheadPosition. Also stores the
 * system time at which the video was paused in pauseStartedTime. Sets
 * isPaused to true so getCurrentPlaybackTime knows the video is in a paused state.
 */

- (void)pausePlayhead
{
    self.pausedPlayheadPosition = self.playheadPosition;
    self.pausedStartedTime = CFAbsoluteTimeGetCurrent();
    self.isPaused = true;
}

/**
 * This method sets the isPaused flag to false, as well as calculates the
 * offset value. The offset represents the total cumulative time in seconds a video was
 * in a paused state during a session. If no offset exists:
 *
 * offset = currentSystemTime - timePlayerWasPaused
 *
 * Otherwise, the offset is added to the existing offset value. This may be the case if a
 * user pauses and unpauses the video many times during a single session:
 *
 * offset = originalOffset + (currentSystemTime - timePlayerWasPaused)
 */

- (void)unPausePlayhead
{
    if (self.offset == 0) {
        self.offset = (CFAbsoluteTimeGetCurrent() - self.pausedStartedTime) / 1000;
    } else {
        self.offset += (CFAbsoluteTimeGetCurrent() - self.pausedStartedTime) / 1000;
    }
    self.isPaused = false;
}

/**
 * Resumes invocation of getCurrentPlaybackTime by setting isPaused to
 * false. This is only called when a customer sends a "Video Playback Seek Completed" event.
 */

- (void)resumePlayheadAfterSeeking
{
    self.isPaused = false;
}

/**
 * Updates member variables initialTime and updatedPlayheadPosition whenever
 * either a "Video Playback Seek Completed" or "Video Content Started" event is received AND
 * contains properties.seekPosition or properties.position, respectively. After invocation,
 * initialTime is assigned to the system time at which the video event was received.
 *
 * @param playheadPosition properties.position passed by the customer into a "Video Playback
 *     Seek Completed" or "Video Content Started" event. This value is required for accurate
 *     reporting in the Adobe dashboard. It defaults to 0.
 */
- (void)updatePlayheadPosition:(long)playheadPosition
{
    self.initialTime = CFAbsoluteTimeGetCurrent();
    self.updatedPlayheadPosition = playheadPosition;
}

@end


@implementation SEGRealPlaybackDelegateFactory
- (SEGPlaybackDelegate *)createPlaybackDelegate
{
    return [[SEGPlaybackDelegate alloc] initWithDelegate:self.playbackDelegate];
}
@end


@implementation SEGRealADBMediaHeartbeatFactory

- (ADBMediaHeartbeat *)createWithDelegate:(id)delegate andConfig:(ADBMediaHeartbeatConfig *)config;
{
    return [[ADBMediaHeartbeat alloc] initWithDelegate:delegate config:config];
}
@end


@implementation SEGRealADBMediaObjectFactory


/**
 Creates an instance of ADBMediaObject to pass through
 Adobe Heartbeat Events.

 ADBMediaObject can build a Video, Chapter, Ad Break or Ad object.
 Passing in a value for event type as Playback, Content, Ad Break
 or Ad will build the relevant instance of ADBMediaObject,
 respectively.
 
 @param properties Properties sent on Segment `track` call
 @param eventType Denotes whether the event is a Playback, Content, or Ad event
 @return An instance of ADBMediaObject
 */
- (ADBMediaObject *_Nullable)createWithProperties:(NSDictionary *_Nullable)properties andEventType:(NSString *_Nullable)eventType;
{
    NSString *videoName = properties[@"title"];
    NSString *mediaId = properties[@"content_asset_id"];
    double length = [properties[@"total_length"] doubleValue];
    NSString *adId = properties[@"asset_id"];

    // TODO: not spec'd, follow up with spec committee proposal
    double startTime = [properties[@"start_time"] doubleValue];
    double position = [properties[@"indexPosition"] doubleValue];

    // Adobe also has a third type: linear, which we have chosen
    // to omit as it does not conform to Segment's Video spec
    bool isLivestream = properties[@"livestream"];
    NSString *streamType = ADBMediaHeartbeatStreamTypeVOD;
    if (isLivestream) {
        streamType = ADBMediaHeartbeatStreamTypeLIVE;
    }

    if ([eventType isEqualToString:@"Playback"]) {
        return [ADBMediaHeartbeat createMediaObjectWithName:videoName
                                                    mediaId:mediaId
                                                     length:length
                                                 streamType:streamType];
    } else if ([eventType isEqualToString:@"Content"]) {
        return [ADBMediaHeartbeat createChapterObjectWithName:videoName
                                                     position:position
                                                       length:length
                                                    startTime:startTime];
    } else if ([eventType isEqualToString:@"Ad Break"]) {
        return [ADBMediaHeartbeat createAdBreakObjectWithName:videoName
                                                     position:position
                                                    startTime:startTime];
    } else if ([eventType isEqualToString:@"Ad"]) {
        return [ADBMediaHeartbeat createAdObjectWithName:videoName
                                                    adId:adId
                                                position:position
                                                  length:length];
    }
    SEGLog(@"Event type not passed through.");
    return nil;
}
@end


@implementation SEGAdobeIntegration

#pragma mark - Initialization

- (instancetype)initWithSettings:(NSDictionary *)settings adobe:(id _Nullable)ADBMobileClass andMediaHeartbeatFactory:(id<SEGADBMediaHeartbeatFactory>)ADBMediaHeartbeatFactory andMediaHeartbeatConfig:(ADBMediaHeartbeatConfig *)config andMediaObjectFactory:(id<SEGADBMediaObjectFactory> _Nullable)ADBMediaObjectFactory andPlaybackDelegateFactory:(id<SEGPlaybackDelegateFactory>)delegateFactory
{
    if (self = [super init]) {
        self.settings = settings;
        self.adobeMobile = ADBMobileClass;
        self.heartbeatFactory = ADBMediaHeartbeatFactory;
        self.objectFactory = ADBMediaObjectFactory;
        self.config = config;
        self.delegateFactory = delegateFactory;
    }

    [self.adobeMobile collectLifecycleData];

    return self;
}

- (void)reset
{
    [self.adobeMobile trackingClearCurrentBeacon];
    SEGLog(@"[ADBMobile trackingClearCurrentBeacon];");
}

- (void)flush
{
    // Choosing to use `trackingSendQueuedHits` in lieu of
    // `trackingClearQueue` because the latter also
    // removes the queued events from the database
    [self.adobeMobile trackingSendQueuedHits];
    SEGLog(@"ADBMobile trackingSendQueuedHits");
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    if (!payload.userId) return;
    [self.adobeMobile setUserIdentifier:payload.userId];
    SEGLog(@"[ADBMobile setUserIdentifier:%@]", payload.userId);
}

- (void)track:(SEGTrackPayload *)payload
{
    // You can send ecommerce events via either a trackAction or trackState call.
    // Since Segment does not spec sending products on `screen`, we
    // will only support sending this via trackAction
    NSDictionary *adobeEcommerceEvents = @{
        @"Product Added" : @"scAdd",
        @"Product Removed" : @"scRemove",
        @"Cart Viewed" : @"scView",
        @"Checkout Started" : @"scCheckout",
        @"Order Completed" : @"purchase",
        @"Product Viewed" : @"prodView"
    };

    NSString *event = payload.event;
    if (adobeEcommerceEvents[event]) {
        NSDictionary *contextData = [self mapProducts:adobeEcommerceEvents[event] andProperties:payload.properties];
        [self.adobeMobile trackAction:adobeEcommerceEvents[event] data:contextData];
        SEGLog(@"[ADBMobile trackAction:%@ data:%@];", event, contextData);
        return;
    }

    NSArray *adobeVideoEvents = @[
        @"Video Playback Started",
        @"Video Playback Paused",
        @"Video Playback Buffer Started",
        @"Video Playback Buffer Completed",
        @"Video Playback Seek Started",
        @"Video Playback Seek Completed",
        @"Video Playback Resumed",
        @"Video Playback Completed",
        @"Video Content Started",
        @"Video Content Completed",
        @"Video Ad Break Started",   // not spec'd
        @"Video Ad Break Completed", // not spec'd
        @"Video Ad Started",
        @"Video Ad Skipped", // not spec'd
        @"Video Ad Completed"
    ];
    for (NSString *videoEvent in adobeVideoEvents) {
        if ([videoEvent isEqualToString:event]) {
            [self trackHeartbeatEvents:payload];
            return;
        }
    }

    event = [self mapEventsV2:event];
    if (!event) {
        SEGLog(@"Event must be configured in Adobe and in the EventsV2 setting in Segment before sending.");
        return;
    }
    NSDictionary *contextData = [self mapContextValues:payload.properties];
    [self.adobeMobile trackAction:event data:contextData];
    SEGLog(@"[ADBMobile trackAction:%@ data:%@];", event, contextData);
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *data = [self mapContextValues:payload.properties];
    [self.adobeMobile trackState:payload.name data:data];
    SEGLog(@"[ADBMobile trackState:%@ data:%@];", payload.name, data);
}

///-------------------------
/// @name Mapping
///-------------------------

/**
 All context data variables must be mapped by using processing rules,
 meaning they must be configured as a context variable in Adobe's UI
 and mapped from a Segment Property to the configured variable in Adobe

 @param properties Segment `track` or `screen` properties
 @return data Dictionary of context data with Adobe key
**/

- (NSMutableDictionary *)mapContextValues:(NSDictionary *)properties
{
    NSInteger contextValuesSize = [self.settings[@"contextValues"] count];
    if ([properties count] > 0 && contextValuesSize > 0) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] initWithCapacity:contextValuesSize];
        NSDictionary *contextValues = self.settings[@"contextValues"];
        for (NSString *key in contextValues) {
            if (properties[key]) {
                [data setObject:properties[key] forKey:contextValues[key]];
            }
        }
        return data;
    }
    return nil;
}

/**
    In order to respect Adobe's event naming convention, Segment
    will have a setting eventsV2 to transform Segment events to
    Adobe's convention.

    If an event is not configured, Segment will not send the
    event to Adobe.

    @param event Event name sent via track
    @return eventV2 Adobe configured event name
 **/

- (NSString *)mapEventsV2:(NSString *)event
{
    NSDictionary *eventsV2 = self.settings[@"eventsV2"];
    for (NSString *key in eventsV2) {
        if ([key isEqualToString:event]) {
            return [eventsV2 objectForKey:key];
        }
    }
    return nil;
}

///-------------------------
/// @name Ecommerce Mapping
///-------------------------

/**
     Adobe expects products to be passed in with the key `&&products`.

     If `&&products` contains multiple products, the end of a product will
     be delimited by a `,`.

     Segment will also send in any additional `contextDataVariables` configured
     in Segment settings.

     If a product-specific event is triggered, it must also be sent with the
     `&&events` variable. Segment will send in the Segment spec'd Ecommerce
     event as the `&&events` variable.

     @param event Event name sent via track
     @param properties Properties sent via track
     @return contextData object with &&events and formatted product String in &&products
 **/

- (NSMutableDictionary *)mapProducts:(NSString *)event andProperties:(NSDictionary *)properties
{
    if ([properties count] == 0) {
        return nil;
    }

    NSMutableDictionary *data = [self mapContextValues:properties];
    NSMutableDictionary *contextData = [[NSMutableDictionary alloc] initWithDictionary:data];

    // If you trigger a product-specific event by using the &&products variable,
    // you must also set that event in the &&events variable.
    // If you do not set that event, it is filtered out during processing.
    [contextData setObject:event forKey:@"&&events"];

    NSString *formattedProducts = @"";
    // If Products is of type NSArray (ex. Order Completed),
    // we must end each product with a `,` to denote multiple products
    NSArray *products = properties[@"products"];
    if ([products isKindOfClass:[NSArray class]]) {
        int count = 0;
        for (NSDictionary *obj in products) {
            NSString *result = [self formatProducts:obj];
            // Catch the case where productIdentifier is nil
            if (result == nil) {
                return nil;
            }
            formattedProducts = [formattedProducts stringByAppendingString:result];
            count++;
            if (count < [products count]) {
                formattedProducts = [formattedProducts stringByAppendingString:@",;"];
            }
        }
    } else {
        formattedProducts = [self formatProducts:properties];
    }

    [contextData setObject:formattedProducts forKey:@"&&products"];
    return contextData;
}

/**
    Adobe expects products to formatted as an NSString, delimited with `;`, with values in the following order:
    `"Category;Product;Quantity;Price;eventN=X[|eventN2=X2];eVarN=merch_category[|eVarN2=merch_category2]"`

     Product is a required argument, so if this is not present, Segment does not create the
     `&&products` String. This value can be the product name, sku, or productId,
     which is configured via the Segment setting `productIdentifier`.

     If the other values in the String are missing, Segment
     will leave the space empty but keep the `;` delimiter to preserve the order
     of the product properties.

    `formatProducts` can take in an object from the products array:

     @"products" : @[
         @{
             @"product_id" : @"2013294",
             @"category" : @"Games",
             @"name" : @"Monopoly: 3rd Edition",
             @"brand" : @"Hasbros",
             @"price" : @"21.99",
             @"quantity" : @"1"
         }
     ]

     And output the following : @"Games;Monopoly: 3rd Edition;1;21.99,;Games;Battleship;2;27.98"

     It can also format a product passed in as a top level property, for example

     @{
         @"product_id" : @"507f1f77bcf86cd799439011",
         @"sku" : @"G-32",
         @"category" : @"Food",
         @"name" : @"Turkey",
         @"brand" : @"Farmers",
         @"variant" : @"Free Range",
         @"price" : @180.99,
         @"quantity" : @1,
     }

     And output the following:  @"Food;G-32;1;180.99"

     @param obj Product from the products array

     @return Product string representing one product
 **/

- (NSString *)formatProducts:(NSDictionary *)obj
{
    NSString *category = obj[@"category"] ?: @"";

    // The product argument is REQUIRED for Adobe ecommerce events.
    // This value can be 'name', 'sku', or 'id'. Defaults to name
    NSString *productIdentifier = obj[self.settings[@"productIdentifier"]];

    // Fallback to id. Segment's ecommerce v1 Spec'd `id` as the product identifier
    // The setting productIdentifier checks for id, where ecommerce V2
    // is expecting product_id.
    if ([self.settings[@"productIdentifier"] isEqualToString:@"id"]) {
        productIdentifier = obj[@"product_id"] ?: obj[@"id"];
    }

    if ([productIdentifier length] == 0) {
        NSLog(@"Product is a required field.");
        return nil;
    }


    // Adobe expects Price to refer to the total price (unit price x units).
    int quantity = [obj[@"quantity"] intValue] ?: 1;
    double price = [obj[@"price"] doubleValue] ?: 0;
    double total = price * quantity;

    NSArray *output = @[ category, productIdentifier, [NSNumber numberWithInt:quantity], [NSNumber numberWithDouble:total] ];
    return [output componentsJoinedByString:@";"];
}

///-------------------------
/// @name Video Tracking
///-------------------------


/**
 Event tracking for Adobe Heartbeats.

 Must follow Segment's Video Spec to leverage Adobe Heartbeat tracking.
 https://segment.com/docs/spec/video/

 @param payload Payload sent on Segment `track` call
 */
- (void)trackHeartbeatEvents:(SEGTrackPayload *)payload
{
    if ([payload.event isEqualToString:@"Video Playback Started"]) {
        self.config = [self createConfig:payload];
        // createConfig can return nil if the Adobe required field
        // trackingServer is not properly configured in Segment's UI.
        if (!self.config) {
            return;
        }

        self.playbackDelegate = [self.delegateFactory createPlaybackDelegate];
        self.mediaHeartbeat = [self.heartbeatFactory createWithDelegate:self.playbackDelegate andConfig:self.config];
        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Playback"];
        //TODO: check to see if we need to handle custom metadata (second argument) like with
        // contextDataVariables
        [self.mediaHeartbeat trackSessionStart:self.mediaObject data:payload.properties];
        SEGLog(@"[ADBMediaHeartbeat trackSessionStart:%@ data:@%]", self.mediaObject, payload.properties);
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Paused"]) {
        [self.playbackDelegate pausePlayhead];
        [self.mediaHeartbeat trackPause];
        SEGLog(@"[ADBMediaHeartbeat trackPause]");
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Resumed"]) {
        [self.playbackDelegate unPausePlayhead];
        [self.mediaHeartbeat trackPlay];
        SEGLog(@"[ADBMediaHeartbeat trackPlay]");
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Completed"]) {
        [self.mediaHeartbeat trackSessionEnd];
        SEGLog(@"[ADBMediaHeartbeat trackSessionEnd]");
        return;
    }

    if ([payload.event isEqualToString:@"Video Content Started"]) {
        if ([payload.properties[@"position"] doubleValue] > 0) {
            [self.playbackDelegate updatePlayheadPosition:[payload.properties[@"position"] longValue]];
        };

        [self.mediaHeartbeat trackPlay];
        SEGLog(@"[ADBMediaHeartbeat trackPlay]");

        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Content"];
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterStart mediaObject:self.mediaObject data:payload.properties];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterStart mediaObject:%@ data:%@]", self.mediaObject, payload.properties);
        return;
    }

    if ([payload.event isEqualToString:@"Video Content Completed"]) {
        [self.mediaHeartbeat trackComplete];
        SEGLog(@"[ADBMediaHeartbeat trackComplete]");

        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Content"];

        // Adobe examples show that the mediaObject and data should be nil on Chapter Complete events
        // https://github.com/Adobe-Marketing-Cloud/video-heartbeat-v2/blob/master/sdks/iOS/samples/BasicPlayerSample/BasicPlayerSample/Classes/analytics/VideoAnalyticsProvider.m#L158
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterComplete mediaObject:nil data:nil];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventChapterComplete mediaObject:nil data:nil]");
        return;
    }

    NSDictionary *videoTrackEvents = @{
        @"Video Playback Buffer Started" : @(ADBMediaHeartbeatEventBufferStart),
        @"Video Playback Buffer Completed" : @(ADBMediaHeartbeatEventBufferComplete),
        @"Video Playback Seek Started" : @(ADBMediaHeartbeatEventSeekStart),
        @"Video Playback Seek Completed" : @(ADBMediaHeartbeatEventSeekComplete)
    };

    enum ADBMediaHeartbeatEvent videoEvent = [videoTrackEvents[payload.event] intValue];
    switch (videoEvent) {
        case ADBMediaHeartbeatEventBufferStart:
        case ADBMediaHeartbeatEventSeekStart:
            [self.playbackDelegate pausePlayhead];
            break;
        case ADBMediaHeartbeatEventBufferComplete:
            [self.playbackDelegate unPausePlayhead];
            break;
        case ADBMediaHeartbeatEventSeekComplete:
            [self.playbackDelegate updatePlayheadPosition:[payload.properties[@"seek_position"] longValue]];
            [self.playbackDelegate resumePlayheadAfterSeeking];
            break;
        default:
            break;
    }

    if (videoEvent) {
        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Video"];
        [self.mediaHeartbeat trackEvent:videoEvent mediaObject:self.mediaObject data:payload.properties];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventBufferStart mediaObject:%@ data:%@]", self.mediaObject, payload.properties);
        return;
    }

    if ([payload.event isEqualToString:@"Video Playback Interrupted"]) {
        [self.playbackDelegate pausePlayhead];
        return;
    }

    // Video Ad Break Started/Completed are not spec'd. For now, will document for Adobe and
    // write a proposal to add this to the Video Spec
    if ([payload.event isEqualToString:@"Video Ad Break Started"]) {
        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Ad Break"];
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakStart mediaObject:self.mediaObject data:nil];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakStart mediaObject:%@ data:nil]", self.mediaObject);
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Break Completed"]) {
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakComplete mediaObject:nil data:nil];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdBreakComplete mediaObject:nil data:nil]");
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Started"]) {
        self.mediaObject = [self createMediaObject:payload.properties andEventType:@"Ad"];
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdStart mediaObject:self.mediaObject data:payload.properties];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdStart mediaObject:%@ data:%@]", self.mediaObject, payload.properties);
        return;
    }

    // Not spec'd
    if ([payload.event isEqualToString:@"Video Ad Skipped"]) {
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdSkip mediaObject:nil data:nil];
        SEGLog(@"[ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdSkip mediaObject:nil data:nil]");
        return;
    }

    if ([payload.event isEqualToString:@"Video Ad Completed"]) {
        [self.mediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdComplete mediaObject:nil data:nil];
        SEGLog(@"[self.ADBMediaHeartbeat trackEvent:ADBMediaHeartbeatEventAdComplete mediaObject:nil data:nil];");
        return;
    }
}

/**
 Create a MediaHeartbeatConfig instance required to
 initialize an instance of ADBMediaHearbeat

 The only required value is the trackingServer,
 which is configured via the Segment Integration
 Settings UI under heartbeat tracking server.

 @param payload Payload sent on Segment `track` call
 @return config Instance of MediaHeartbeatConfig
 */
- (ADBMediaHeartbeatConfig *)createConfig:(SEGTrackPayload *)payload
{
    NSDictionary *properties = payload.properties;
    NSDictionary *options = payload.integrations[@"Adobe Analytics"];

    BOOL sslEnabled = false;
    if (self.settings[@"ssl"]) {
        sslEnabled = true;
    }

    BOOL debugEnabled = false;
    if (options[@"debug"]) {
        debugEnabled = true;
    }

    NSMutableDictionary *infoDictionary = [[[NSBundle mainBundle] infoDictionary] mutableCopy];
    [infoDictionary addEntriesFromDictionary:[[NSBundle mainBundle] localizedInfoDictionary]];
    self.config.appVersion = infoDictionary[@"CFBundleShortVersionString"] ?: @"unknown";

    if ([self.settings[@"heartbeatTrackingServer"] length] == 0) {
        SEGLog(@"Adobe requires a heartbeat tracking sever configured via Segment's UI in order to initialize and start tracking heartbeat events.");
        return nil;
    }
    self.config.trackingServer = self.settings[@"heartbeatTrackingServer"];
    self.config.channel = properties[@"channel"] ?: @"";
    self.config.ovp = options[@"ovp_name"] ?: @"unknown";
    self.config.playerName = properties[@"video_player"] ?: @"";
    self.config.ssl = sslEnabled;
    self.config.debugLogging = debugEnabled;

    return self.config;
}


/**
 Adobe has standard video metadata to pass in on
 Segment's Video Playback events.

 @param properties Properties passed in on Segment `track`
 @return A dictionary of mapped Standard Video metadata
 */
- (NSMutableDictionary *)mapStandardVideoMetadata:(NSDictionary *)properties andEventType:(NSString *)eventType
{
    NSDictionary *videoMetadata = @{
        @"asset_id" : ADBVideoMetadataKeyASSET_ID,
        @"program" : ADBVideoMetadataKeySHOW,
        @"season" : ADBVideoMetadataKeySEASON,
        @"episode" : ADBVideoMetadataKeyEPISODE,
        @"genre" : ADBVideoMetadataKeyGENRE,
        @"channel" : ADBVideoMetadataKeyNETWORK,
        @"airdate" : ADBVideoMetadataKeyFIRST_AIR_DATE,
    };
    NSMutableDictionary *standardVideoMetadata = [[NSMutableDictionary alloc] init];

    for (id key in videoMetadata) {
        if (properties[key]) {
            [standardVideoMetadata setObject:properties[key] forKey:videoMetadata[key]];
        }
    }

    // Segment's paublisher property exists on the content and ad level. Adobe
    // needs to interpret this either as and Advertiser (ad events) or Originator (content events)
    if ([eventType isEqualToString:@"Ad"] || [eventType isEqualToString:@"Ad Break"]) {
        [standardVideoMetadata setObject:properties[@"publisher"] forKey:ADBAdMetadataKeyADVERTISER];
    } else if ([eventType isEqualToString:@"Content"]) {
        [standardVideoMetadata setObject:properties[@"publisher"] forKey:ADBVideoMetadataKeyORIGINATOR];
    }

    // Adobe also has a third type: linear, which we have chosen
    // to omit as it does not conform to Segment's Video spec
    bool isLivestream = properties[@"livestream"];
    if (isLivestream) {
        [standardVideoMetadata setObject:ADBMediaHeartbeatStreamTypeLIVE forKey:ADBVideoMetadataKeySTREAM_FORMAT];
    } else {
        [standardVideoMetadata setObject:ADBMediaHeartbeatStreamTypeVOD forKey:ADBVideoMetadataKeySTREAM_FORMAT];
    }

    return standardVideoMetadata;
}

- (ADBMediaObject *)createMediaObject:(NSDictionary *)properties andEventType:(NSString *)eventType
{
    self.mediaObject = [self.objectFactory createWithProperties:properties andEventType:eventType];
    NSMutableDictionary *standardVideoMetadata = [self mapStandardVideoMetadata:properties andEventType:eventType];
    [self.mediaObject setValue:standardVideoMetadata forKey:ADBMediaObjectKeyStandardVideoMetadata];
    return self.mediaObject;
}

@end
