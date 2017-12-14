//
//  Segment-Adobe-AnalyticsTests.m
//  Segment-Adobe-AnalyticsTests
//
//  Created by ladanazita on 11/07/2017.
//  Copyright (c) 2017 Segment. All rights reserved.
//

// https://github.com/Specta/Specta


@interface SEGMockADBMediaHeartbeatFactory : NSObject <SEGADBMediaHeartbeatFactory>
@property (nonatomic, strong) ADBMediaHeartbeat *mediaHeartbeat;
@property (nonatomic, strong) ADBMediaHeartbeatConfig *config;
@end


@implementation SEGMockADBMediaHeartbeatFactory
- (ADBMediaHeartbeat *)createWithDelegate:(id)delegate andConfig:(ADBMediaHeartbeatConfig *)config
{
    return self.mediaHeartbeat;
}
@end


@interface SEGMockADBMediaObjectFactory : NSObject <SEGADBMediaObjectFactory>
@property (nonatomic, strong) ADBMediaObject *mediaObject;
@end


@implementation SEGMockADBMediaObjectFactory
- (ADBMediaObject *)createWithProperties:(NSDictionary *)properties andEventType:(NSString *_Nullable)eventType
{
    return self.mediaObject;
}
@end


@interface SEGMockPlaybackDelegateFactory : NSObject <SEGPlaybackDelegateFactory>
@property (nonatomic, strong) SEGPlaybackDelegate *playbackDelegate;
@end


@implementation SEGMockPlaybackDelegateFactory
- (SEGPlaybackDelegate *_Nullable)createPlaybackDelegateWithPosition:(long)playheadPosition
{
    return self.playbackDelegate;
}
@end

SpecBegin(InitialSpecs);

describe(@"SEGAdobeIntegration", ^{
    __block ADBMobile *mockADBMobile;
    __block SEGAdobeIntegration *integration;

    describe(@"SEGAdobeIntegrationFactory", ^{
        it(@"factory creates integration with basic settings", ^{
            SEGAdobeIntegration *integration = [[SEGAdobeIntegrationFactory instance] createWithSettings:@{} forAnalytics:nil];
            [verify(mockADBMobile) collectLifecycleData];
        });
    });

    beforeEach(^{
        mockADBMobile = mockClass([ADBMobile class]);
        integration = [[SEGAdobeIntegration alloc] initWithSettings:@{} adobe:mockADBMobile andMediaHeartbeatFactory:nil andMediaHeartbeatConfig:nil andMediaObjectFactory:nil andPlaybackDelegateFactory:nil];
    });

    describe(@"reset", ^{
        it(@"resets user", ^{
            [integration reset];
            [verify(mockADBMobile) trackingClearCurrentBeacon];
        });
    });

    describe(@"flush", ^{
        it(@"flushes queue", ^{
            [integration flush];
            [verify(mockADBMobile) trackingSendQueuedHits];
        });
    });

    describe(@"identify", ^{
        it(@"it does not identify an unknown user", ^{
            SEGIdentifyPayload *identifyPayload = [[SEGIdentifyPayload alloc] initWithUserId:nil anonymousId:@"324908523402" traits:@{
                @"gender" : @"female",
                @"name" : @"ladan"
            } context:@{}
                integrations:@{}];

            [integration identify:identifyPayload];
            [verifyCount(mockADBMobile, never()) setUserIdentifier:nil];
        });

        it(@"it identifies a known user", ^{
            SEGIdentifyPayload *identifyPayload = [[SEGIdentifyPayload alloc] initWithUserId:@"2304920517" anonymousId:@"324908523402" traits:@{
                @"gender" : @"female",
                @"name" : @"ladan"
            } context:@{}
                integrations:@{}];

            [integration identify:identifyPayload];
            [verify(mockADBMobile) setUserIdentifier:@"2304920517"];
        });
    });

    describe(@"track", ^{
        it(@"does not track an action without eventsV2", ^{
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Testing" properties:@{} context:@{} integrations:@{}];
            [integration track:trackPayload];
            [verifyCount(mockADBMobile, never()) trackAction:@"myapp.testing" data:nil];
        });

        it(@"tracks an action without properties but with settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{
                @"contextValues" : @{
                    @"plan" : @"myapp.plan",
                    @"subscribed" : @"myapp.subscribed",
                },
                @"eventsV2" : @{
                    @"Signed Up" : @"myapp.signedup",
                    @"Testing" : @"myapp.testing"
                }
            } adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Testing" properties:@{} context:@{} integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"myapp.testing" data:nil];
        });

        it(@"tracks an action with nil properties if they are NOT configured in settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"eventsV2" : @{
                @"Signed Up" : @"myapp.signedup",
                @"Testing" : @"myapp.testing"
            } } adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];

            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Testing" properties:@{ @"plan" : @"self-service" } context:@{} integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"myapp.testing" data:nil];
        });

        it(@"tracks an action with some properties configured in settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"contextValues" : @{
                @"plan" : @"myapp.plan",
                @"subscribed" : @"myapp.subscribed"
            },
                                                                           @"eventsV2" : @{
                                                                               @"Testing" : @"myapp.testing"
                                                                           }
            } adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Testing" properties:@{ @"plan" : @"self-service" }
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"myapp.testing" data:@{ @"myapp.plan" : @"self-service" }];
        });
    });

    describe(@"screen", ^{
        it(@"tracks a screen state without propertiesbut with settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"contextValues" : @{
                @"plan" : @"myapp.plan",
                @"subscribed" : @"myapp.subscribed"
            } } adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            SEGScreenPayload *screenPayload = [[SEGScreenPayload alloc] initWithName:@"Login" properties:@{} context:@{} integrations:@{}];
            [integration screen:screenPayload];
            [verify(mockADBMobile) trackState:@"Login" data:nil];
        });

        it(@"tracks a screen state with properties NOT configured in settings.contextValues", ^{
            SEGScreenPayload *screenPayload = [[SEGScreenPayload alloc] initWithName:@"Sign Up" properties:@{ @"new_user" : @YES } context:@{} integrations:@{}];
            [integration screen:screenPayload];
            [verify(mockADBMobile) trackState:@"Sign Up" data:nil];
        });

        it(@"tracks a screen state with some properties configured in settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"contextValues" : @{@"title" : @"myapp.title",
                                                                                                @"new_user" : @"myapp.new_user"} }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];

            SEGScreenPayload *screenPayload = [[SEGScreenPayload alloc] initWithName:@"Sign Up" properties:@{ @"new_user" : @YES }
                context:@{}
                integrations:@{}];
            [integration screen:screenPayload];
            [verify(mockADBMobile) trackState:@"Sign Up" data:@{ @"myapp.new_user" : @YES }];
        });
    });

    describe(@"ecommmerce", ^{
        beforeEach(^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"productIdentifier" : @"name" }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
        });

        it(@"tracks Product Added with productIdentifier product_id", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"productIdentifier" : @"id" }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Product Added" properties:@{
                @"cart_id" : @"skdjsidjsdkdj29j",
                @"product_id" : @"507f1f77bcf86cd799439011",
                @"sku" : @"G-32",
                @"category" : @"Games",
                @"name" : @"Monopoly: 3rd Edition",
                @"brand" : @"Hasbro",
                @"variant" : @"200 pieces",
                @"price" : @18.99,
                @"quantity" : @1,
                @"coupon" : @"MAYDEALS",
                @"position" : @3,
                @"url" : @"https://www.company.com/product/path",
                @"image_url" : @"https://www.company.com/product/path.jpg"
            }
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scAdd" data:@{
                @"&&events" : @"scAdd",
                @"&&products" : @"Games;507f1f77bcf86cd799439011;1;18.99"
            }];
        });

        it(@"tracks Product Added with productIdentifier falling back to id", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"productIdentifier" : @"id" }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Product Added" properties:@{
                @"cart_id" : @"skdjsidjsdkdj29j",
                @"id" : @"507f1f77bcf86cd799439011",
                @"sku" : @"G-32",
                @"category" : @"Games",
                @"name" : @"Monopoly: 3rd Edition",
                @"brand" : @"Hasbro",
                @"variant" : @"200 pieces",
                @"price" : @18.99,
                @"quantity" : @1,
                @"coupon" : @"MAYDEALS",
                @"position" : @3,
                @"url" : @"https://www.company.com/product/path",
                @"image_url" : @"https://www.company.com/product/path.jpg"
            }
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scAdd" data:@{
                @"&&events" : @"scAdd",
                @"&&products" : @"Games;507f1f77bcf86cd799439011;1;18.99"
            }];
        });

        it(@"tracks Product Removed without properties", ^{
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Product Removed" properties:@{}
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scRemove" data:nil];
        });

        it(@"tracks Product Removed without quantity and price", ^{
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Product Removed" properties:@{
                @"cart_id" : @"skdjsidjsdkdj29j",
                @"product_id" : @"507f1f77bcf86cd799439011",
                @"sku" : @"G-32",
                @"category" : @"Games",
                @"name" : @"Monopoly: 3rd Edition",
                @"brand" : @"Hasbro",
                @"variant" : @"200 pieces",
                @"coupon" : @"MAYDEALS",
                @"position" : @3,
                @"url" : @"https://www.company.com/product/path",
                @"image_url" : @"https://www.company.com/product/path.jpg"
            }
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scRemove" data:@{
                @"&&events" : @"scRemove",
                @"&&products" : @"Games;Monopoly: 3rd Edition;1;0"
            }];
        });

        it(@"does not track products on Cart Viewed without required product identifier", ^{
            NSDictionary *props = @{
                @"share_via" : @"email",
                @"share_message" : @"Hey, check out this item",
                @"recipient" : @"friend@gmail.com",
                @"cart_id" : @"d92jd29jd92jd29j92d92jd",
                @"products" : @[
                    @{@"product_id" : @"507f1f77bcf86cd799439011"},
                    @{@"product_id" : @"505bd76785ebb509fc183733"}
                ]
            };

            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Cart Viewed" properties:props
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scView" data:nil];
        });

        it(@"tracks Product Viewed with product identifier as sku", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"productIdentifier" : @"sku" }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:nil
                                                andMediaHeartbeatConfig:nil
                                                  andMediaObjectFactory:nil
                                             andPlaybackDelegateFactory:nil];
            NSDictionary *props = @{
                @"product_id" : @"507f1f77bcf86cd799439011",
                @"sku" : @"G-32",
                @"category" : @"Food",
                @"name" : @"Turkey",
                @"brand" : @"Farmers",
                @"variant" : @"Free Range",
                @"price" : @180.99,
                @"quantity" : @1,
                @"coupon" : @"TURKEYDAY",
                @"currency" : @"usd",
                @"position" : @3,
                @"value" : @20.99,
                @"url" : @"https://www.company.com/product/path",
                @"image_url" : @"https://www.company.com/product/path.jpg"
            };

            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Product Viewed" properties:props
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"prodView" data:@{
                @"&&events" : @"prodView",
                @"&&products" : @"Food;G-32;1;180.99"
            }];
        });

        it(@"tracks Checkout Started without category", ^{
            NSDictionary *props = @{
                @"checkout_id" : @"4230523091",
                @"order_id" : @"13125032",
                @"affiliation" : @"Google Play",
                @"total" : @16.18,
                @"tax" : @2.20,
                @"currency" : @"USD",
                @"revenue" : @8,
                @"products" : @[
                    @{
                       @"product_id" : @"2013294",
                       @"name" : @"Farmville",
                       @"brand" : @"Zynga",
                       @"price" : @"9.99",
                       @"quantity" : @"1"
                    },
                    @{
                       @"product_id" : @"149820",
                       @"name" : @"Words With Friends",
                       @"brand" : @"Zynga",
                       @"price" : @"3.99",
                       @"quantity" : @"1"
                    }
                ]
            };
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Checkout Started" properties:props
                context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"scCheckout" data:@{
                @"&&events" : @"scCheckout",
                @"&&products" : @";Farmville;1;9.99,;;Words With Friends;1;3.99"
            }];
        });

        it(@"tracks Order Completed with products", ^{
            NSDictionary *props = @{
                @"checkout_id" : @"9bcf000000000000",
                @"order_id" : @"50314b8e",
                @"affiliation" : @"App Store",
                @"total" : @30.45,
                @"shipping" : @5.05,
                @"tax" : @1.20,
                @"currency" : @"USD",
                @"category" : @"Games",
                @"revenue" : @8,
                @"products" : @[
                    @{
                       @"product_id" : @"2013294",
                       @"category" : @"Games",
                       @"name" : @"Monopoly: 3rd Edition",
                       @"brand" : @"Hasbros",
                       @"price" : @"21.99",
                       @"quantity" : @"1"
                    },
                    @{
                       @"product_id" : @"149820",
                       @"category" : @"Games",
                       @"name" : @"Battleship",
                       @"brand" : @"Hasbros",
                       @"price" : @"13.99",
                       @"quantity" : @"2"
                    }
                ]
            };

            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Order Completed" properties:props context:@{}
                integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"purchase" data:@{
                @"&&events" : @"purchase",
                @"&&products" : @"Games;Monopoly: 3rd Edition;1;21.99,;Games;Battleship;2;27.98"
            }];
        });
    });

    describe(@"video tracking", ^{
        __block ADBMediaHeartbeat *mockADBMediaHeartbeat;
        __block ADBMediaHeartbeatConfig *config = [[ADBMediaHeartbeatConfig alloc] init];
        __block ADBMediaObject *mockADBMediaObject;
        __block SEGPlaybackDelegate *mockPlaybackDelegate;

        beforeEach(^{
            mockADBMediaHeartbeat = mock([ADBMediaHeartbeat class]);
            mockADBMediaObject = mock([ADBMediaObject class]);
            mockPlaybackDelegate = mock([SEGPlaybackDelegate class]);

            SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
            mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

            SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
            mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

            SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
            mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"heartbeatTrackingServer" : @"example",
                                                                           @"ssl" : @YES }
                                                                  adobe:mockADBMobile
                                               andMediaHeartbeatFactory:mockADBMediaHeartbeatFactory
                                                andMediaHeartbeatConfig:config
                                                  andMediaObjectFactory:mockADBMediaObjectFactory
                                             andPlaybackDelegateFactory:mockPlaybackDelegateFactory];
        });

        describe(@"initialization", ^{
            SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
            mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

            it(@"Video Playback Started initializes ADBMediaHeartbeat object", ^{
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
                    @"content_asset_id" : @"1234",
                    @"ad_type" : @"pre-roll",
                    @"video_player" : @"Netflix",
                    @"channel" : @"Cartoon Network"
                } context:@{}
                                                                     integrations:@{ @"Adobe Analytics" : @{@"ovp_name" : @"Netflix", @"debug" : @YES} }];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackSessionStart:mockADBMediaObject data:nil];
                assertThat(config.trackingServer, is(@"example"));
                assertThat(config.channel, is(@"Cartoon Network"));
                assertThat(config.playerName, is(@"Netflix"));
                assertThat(config.ovp, is(@"Netflix"));
                assertThat(config.appVersion, is(@"1.0"));
                assertThatBool(config.ssl, isTrue());
                assertThatBool(config.debugLogging, isTrue());
            });

            it(@"Video Playback Started initializes ADBMediaHeartbeat object with default values", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
                mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

                integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"heartbeatTrackingServer" : @"example" }
                                                                      adobe:mockADBMobile
                                                   andMediaHeartbeatFactory:mockADBMediaHeartbeatFactory
                                                    andMediaHeartbeatConfig:config
                                                      andMediaObjectFactory:mockADBMediaObjectFactory
                                                 andPlaybackDelegateFactory:mockPlaybackDelegateFactory];
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
                    @"content_asset_id" : @"1234",
                    @"ad_type" : @"pre-roll"
                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackSessionStart:mockADBMediaObject data:nil];
                assertThat(config.trackingServer, is(@"example"));
                assertThat(config.channel, is(@""));
                assertThat(config.playerName, is(@""));
                assertThat(config.ovp, is(@"unknown"));
                assertThatBool(config.ssl, isFalse());
                assertThatBool(config.debugLogging, isFalse());
            });

            it(@"does not initialize ADBMediaHeartbeat if video tracking server is not configured", ^{
                mockADBMediaHeartbeat = mock([ADBMediaHeartbeat class]);
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
                mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

                integration = [[SEGAdobeIntegration alloc] initWithSettings:@{}
                                                                      adobe:mockADBMobile
                                                   andMediaHeartbeatFactory:mockADBMediaHeartbeatFactory
                                                    andMediaHeartbeatConfig:config
                                                      andMediaObjectFactory:mockADBMediaObjectFactory
                                                 andPlaybackDelegateFactory:mockPlaybackDelegateFactory];
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{
                    @"content_asset_id" : @"1234",
                    @"ad_type" : @"pre-roll",
                    @"video_player" : @"Netflix",
                    @"channel" : @"Cartoon Network"
                } context:@{}
                                                                     integrations:@{ @"Adobe Analytics" : @{@"ovp_name" : @"Netflix", @"debug" : @YES} }];

                [integration track:payload];
                [verifyCount(mockADBMediaHeartbeat, never()) trackSessionStart:mockADBMediaObject data:@{}];
            });
        });

        describe(@"Video Playback Events", ^{
            beforeEach(^{
                // Video Playback Started initializes an instance of ADBMediaHeartbeat, which we need for testing subsequent Video Events
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{} context:@{}
                    integrations:@{}];
                [integration track:payload];
            });

            it(@"track Video Playback Paused", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Paused" properties:@{
                    @"content_asset_id" : @"7890",
                    @"ad_type" : @"mid-roll",
                    @"video_player" : @"vimeo",
                    @"position" : @30,
                    @"sound" : @100,
                    @"full_screen" : @YES,
                    @"bitrate" : @50
                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) pausePlayhead];
                [verify(mockADBMediaHeartbeat) trackPause];
            });

            it(@"track Video Playback Buffer Started", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;


                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Started" properties:@{
                    @"content_asset_id" : @"2340",
                    @"ad_type" : @"post-roll",
                    @"video_player" : @"youtube",
                    @"position" : @190,
                    @"sound" : @100,
                    @"full_screen" : @NO,
                    @"bitrate" : @50

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) pausePlayhead];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventBufferStart mediaObject:mockADBMediaObject data:nil];
            });

            it(@"track Video Playback Buffer Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Buffer Completed" properties:@{
                    @"content_asset_id" : @"1230",
                    @"ad_type" : @"mid-roll",
                    @"video_player" : @"youtube",
                    @"position" : @90,
                    @"sound" : @100,
                    @"full_screen" : @NO,
                    @"bitrate" : @50

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) unPausePlayhead];
                [verify(mockPlaybackDelegate) updatePlayheadPosition:90];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventBufferComplete mediaObject:mockADBMediaObject data:nil];
            });

            it(@"track Video Playback Seek Started", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Started" properties:@{
                    @"content_asset_id" : @"6352",
                    @"ad_type" : @"pre-roll",
                    @"video_player" : @"vimeo",
                    @"seek_position" : @20,
                    @"sound" : @100,
                    @"full_screen" : @YES,
                    @"bitrate" : @50

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) pausePlayhead];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventSeekStart mediaObject:mockADBMediaObject data:nil];
            });

            it(@"track Video Playback Seek Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Seek Completed" properties:@{
                    @"content_asset_id" : @"6352",
                    @"ad_type" : @"pre-roll",
                    @"video_player" : @"vimeo",
                    @"seek_position" : @20,
                    @"position" : @20,
                    @"sound" : @100,
                    @"full_screen" : @YES,
                    @"bitrate" : @50

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) unPausePlayhead];
                [verify(mockPlaybackDelegate) updatePlayheadPosition:20];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventSeekComplete mediaObject:mockADBMediaObject data:nil];
            });

            it(@"track Video Playback Resumed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Resumed" properties:@{
                    @"content_asset_id" : @"2141",
                    @"ad_type" : @"mid-roll",
                    @"video_player" : @"youtube",
                    @"position" : @34,
                    @"sound" : @100,
                    @"full_screen" : @YES,
                    @"bitrate" : @50

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) unPausePlayhead];
                [verify(mockADBMediaHeartbeat) trackPlay];
            });

            it(@"track Video Playback Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Completed" properties:@{
                    @"content_asset_id" : @"7890",
                    @"ad_type" : @"mid-roll",
                    @"video_player" : @"vimeo",
                    @"position" : @30,
                    @"sound" : @100,
                    @"full_screen" : @YES,
                    @"bitrate" : @50
                }
                    context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) pausePlayhead];
                [verify(mockADBMediaHeartbeat) trackSessionEnd];
            });

        });

        describe(@"Content Events", ^{
            beforeEach(^{
                // Video Playback Started initializes an instance of ADBMediaHeartbeat, which we need for testing subsequent Video Events
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{} context:@{}
                    integrations:@{}];
                [integration track:payload];
            });
            it(@"track Video Content Started", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Started" properties:@{
                    @"asset_id" : @"3543",
                    @"pod_id" : @"65462",
                    @"title" : @"Big Trouble in Little Sanchez",
                    @"season" : @"2",
                    @"episode" : @"7",
                    @"genre" : @"cartoon",
                    @"program" : @"Rick and Morty",
                    @"total_length" : @400,
                    @"full_episode" : @YES,
                    @"publisher" : @"Turner Broadcasting Network",
                    @"position" : @22,
                    @"channel" : @"Cartoon Network",
                    @"start_time" : @140,
                    @"position" : @5
                } context:@{}
                    integrations:@{}];
                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackPlay];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventChapterStart mediaObject:mockADBMediaObject data:nil];
            });

            it(@"track Video Content Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Content Completed" properties:@{
                    @"asset_id" : @"3543",
                    @"pod_id" : @"65462",
                    @"title" : @"Big Trouble in Little Sanchez",
                    @"season" : @"2",
                    @"episode" : @"7",
                    @"genre" : @"cartoon",
                    @"program" : @"Rick and Morty",
                    @"total_length" : @400,
                    @"full_episode" : @"true",
                    @"publisher" : @"Turner Broadcasting Network",
                    @"channel" : @"Cartoon Network"
                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackComplete];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventChapterComplete mediaObject:nil data:nil];
            });
        });

        describe(@"Ad Events", ^{
            beforeEach(^{
                // Video Playback Started initializes an instance of ADBMediaHeartbeat, which we need for testing subsequent Video Events
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{} context:@{}
                    integrations:@{}];
                [integration track:payload];
            });
            it(@"tracks Video Ad Break Started", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Break Started"
                    properties:@{
                        @"asset_id" : @"1231312",
                        @"pod_id" : @"43434234534",
                        @"type" : @"mid-roll",
                        @"total_length" : @110,
                        @"position" : @43,
                        @"publisher" : @"Adult Swim",
                        @"title" : @"Rick and Morty Ad"
                    }
                    context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventAdBreakStart mediaObject:mockADBMediaObject data:nil];

            });

            it(@"tracks Video Ad Break Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Break Completed"
                    properties:@{
                        @"asset_id" : @"1231312",
                        @"pod_id" : @"43434234534",
                        @"type" : @"mid-roll",
                        @"total_length" : @110,
                        @"position" : @43,
                        @"publisher" : @"Adult Swim",
                        @"title" : @"Rick and Morty Ad"
                    }
                    context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventAdBreakComplete mediaObject:nil data:nil];

            });

            it(@"tracks Video Ad Started", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockADBMediaObjectFactory *mockADBMediaObjectFactory = [[SEGMockADBMediaObjectFactory alloc] init];
                mockADBMediaObjectFactory.mediaObject = mockADBMediaObject;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Started"
                    properties:@{
                        @"asset_id" : @"1231312",
                        @"pod_id" : @"43434234534",
                        @"type" : @"mid-roll",
                        @"total_length" : @110,
                        @"position" : @43,
                        @"publisher" : @"Adult Swim",
                        @"title" : @"Rick and Morty Ad"
                    }
                    context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventAdStart mediaObject:mockADBMediaObject data:nil];
            });

            it(@"tracks Video Ad Skipped", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Skipped" properties:@{
                    @"asset_id" : @"1231312",
                    @"pod_id" : @"43434234534",
                    @"type" : @"mid-roll",
                    @"total_length" : @110,
                    @"title" : @"Rick and Morty Ad"

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventAdSkip mediaObject:nil data:nil];
            });

            it(@"tracks Video Ad Completed", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Ad Completed" properties:@{
                    @"asset_id" : @"1231312",
                    @"pod_id" : @"43434234534",
                    @"type" : @"mid-roll",
                    @"total_length" : @110,
                    @"title" : @"Rick and Morty Ad"

                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockADBMediaHeartbeat) trackEvent:ADBMediaHeartbeatEventAdComplete mediaObject:nil data:nil];
            });

        });
        describe(@"Quality of Service Events", ^{
            beforeEach(^{
                // Video Playback Started initializes an instance of ADBMediaHeartbeat, which we need for testing subsequent Video Events
                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Playback Started" properties:@{} context:@{}
                    integrations:@{}];
                [integration track:payload];
            });

            it(@"tracks Quality of Service event", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
                mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Quality Updated" properties:@{
                    @"bitrate" : @500000,
                    @"startup_time" : @2,
                    @"fps" : @24,
                    @"dropped_frames" : @10
                } context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) createAndUpdateQOSObject:nil];
            });

            it(@"tracks Quality of Service event without properties", ^{
                SEGMockADBMediaHeartbeatFactory *mockADBMediaHeartbeatFactory = [[SEGMockADBMediaHeartbeatFactory alloc] init];
                mockADBMediaHeartbeatFactory.mediaHeartbeat = mockADBMediaHeartbeat;

                SEGMockPlaybackDelegateFactory *mockPlaybackDelegateFactory = [[SEGMockPlaybackDelegateFactory alloc] init];
                mockPlaybackDelegateFactory.playbackDelegate = mockPlaybackDelegate;

                SEGTrackPayload *payload = [[SEGTrackPayload alloc] initWithEvent:@"Video Quality Updated" properties:@{} context:@{}
                    integrations:@{}];

                [integration track:payload];
                [verify(mockPlaybackDelegate) createAndUpdateQOSObject:nil];
            });
        });
    });
});
describe(@"SEGPlaybackDelegate", ^{
    __block SEGPlaybackDelegate *playbackDelegate;
    beforeEach(^{
        playbackDelegate = [[SEGPlaybackDelegate alloc] initWithPlayheadPosition:0];
    });

    it(@"sets playheadPosition with value passed in on initialization", ^{
        playbackDelegate = [[SEGPlaybackDelegate alloc] initWithPlayheadPosition:17];
        assertThatLong(playbackDelegate.playheadPosition, equalToLong(17));
    });

    it(@"sets playheadPositionTime on initialization", ^{
        long currentTime = CFAbsoluteTimeGetCurrent();
        assertThatLong(playbackDelegate.playheadPositionTime, equalToLong(currentTime));
    });

    it(@"getCurrentPlaybackTime increments if not paused", ^{
        playbackDelegate.isPaused = false;
        long initialTime = [playbackDelegate getCurrentPlaybackTime];
        [NSThread sleepForTimeInterval:2];
        assertThatLong(([playbackDelegate getCurrentPlaybackTime]), equalToLong(initialTime + 2));
    });

    it(@"pauses playhead position if paused", ^{
        playbackDelegate = [[SEGPlaybackDelegate alloc] initWithPlayheadPosition:6];
        playbackDelegate.isPaused = true;
        [playbackDelegate getCurrentPlaybackTime];
        assertThatLong(playbackDelegate.playheadPosition, equalToLong(6));
    });

    it(@"pausesPlayhead", ^{
        [playbackDelegate pausePlayhead];
        long currentTime = CFAbsoluteTimeGetCurrent();
        // since we initialized playheadPosition with 0, we don't need to expect an addition value here and can simply assume the delta is returned
        assertThatLong(playbackDelegate.playheadPosition, equalToLong(currentTime - playbackDelegate.playheadPositionTime));
        assertThatLong(playbackDelegate.playheadPositionTime, equalToLong(currentTime));
        assertThatBool(playbackDelegate.isPaused, isTrue());
    });

    it(@"unPausePlayhead", ^{
        [playbackDelegate unPausePlayhead];
        assertThatBool(playbackDelegate.isPaused, isFalse());
    });

    it(@"updatePlayheadPosition", ^{
        [playbackDelegate updatePlayheadPosition:5];
        assertThatLong(playbackDelegate.playheadPositionTime, equalToLong(CFAbsoluteTimeGetCurrent()));
        assertThatLong(playbackDelegate.playheadPosition, equalToLong(5));
    });
});

SpecEnd
