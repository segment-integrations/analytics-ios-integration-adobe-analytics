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
});
SpecEnd
