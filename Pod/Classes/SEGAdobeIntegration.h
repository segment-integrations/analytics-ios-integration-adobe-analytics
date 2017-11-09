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


@interface SEGAdobeIntegration : NSObject <SEGIntegration>

@property (nonatomic, strong, nonnull) NSDictionary *settings;
@property (nonatomic, strong) Class _Nullable ADBMobile;

- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings;
- (instancetype _Nonnull)initWithSettings:(NSDictionary *_Nonnull)settings andADBMobile:(id _Nullable)ADBMobile;

@end
