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
});
SpecEnd
