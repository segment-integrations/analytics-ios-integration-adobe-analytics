//
//  Segment-Adobe-AnalyticsTests.m
//  Segment-Adobe-AnalyticsTests
//
//  Created by ladanazita on 11/07/2017.
//  Copyright (c) 2017 Segment. All rights reserved.
//

// https://github.com/Specta/Specta

SpecBegin(InitialSpecs);

describe(@"SEGAdobeIntegration", ^{
    __block ADBMobile *mockADBMobile;
    __block SEGAdobeIntegration *integration;

    describe(@"SEGAdobeIntegrationFactory", ^{
        it(@"factory creates integration with basic settings", ^{
            SEGAdobeIntegration *integration = [[SEGAdobeIntegrationFactory instance] createWithSettings:@{} forAnalytics:nil];
        });
    });

    beforeEach(^{
        mockADBMobile = mockClass([ADBMobile class]);
        integration = [[SEGAdobeIntegration alloc] initWithSettings:@{} andADBMobile:mockADBMobile];
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
            } andADBMobile:mockADBMobile];
            SEGTrackPayload *trackPayload = [[SEGTrackPayload alloc] initWithEvent:@"Testing" properties:@{} context:@{} integrations:@{}];
            [integration track:trackPayload];
            [verify(mockADBMobile) trackAction:@"myapp.testing" data:nil];
        });

        it(@"tracks an action with nil properties if they are NOT configured in settings.contextValues", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"eventsV2" : @{
                @"Signed Up" : @"myapp.signedup",
                @"Testing" : @"myapp.testing"
            } } andADBMobile:mockADBMobile];
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
            } andADBMobile:mockADBMobile];
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
            } } andADBMobile:mockADBMobile];
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
                                                           andADBMobile:mockADBMobile];
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
                                                           andADBMobile:mockADBMobile];
        });

        it(@"tracks Product Added with productIdentifier product_id", ^{
            integration = [[SEGAdobeIntegration alloc] initWithSettings:@{ @"productIdentifier" : @"id" }
                                                           andADBMobile:mockADBMobile];
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
                                                           andADBMobile:mockADBMobile];
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
                                                           andADBMobile:mockADBMobile];
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

});
SpecEnd
