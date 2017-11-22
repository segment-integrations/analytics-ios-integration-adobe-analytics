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


@implementation SEGAdobeIntegration

#pragma mark - Initialization

- (instancetype)initWithSettings:(NSDictionary *)settings
{
    if (self = [super init]) {
        self.settings = settings;
        self.ADBMobile = [ADBMobile class];
    }

    return self;
}

- (instancetype)initWithSettings:(NSDictionary *)settings andADBMobile:(id _Nullable)ADBMobile
{
    if (self = [super init]) {
        self.settings = settings;
        self.ADBMobile = ADBMobile;
    }
    return self;
}

- (void)reset
{
    [self.ADBMobile trackingClearCurrentBeacon];
    SEGLog(@"[ADBMobile trackingClearCurrentBeacon];");
}

- (void)flush
{
    // Choosing to use `trackingSendQueuedHits` in lieu of
    // `trackingClearQueue` because the latter also
    // removes the queued events from the database
    [self.ADBMobile trackingSendQueuedHits];
    SEGLog(@"ADBMobile trackingSendQueuedHits");
}

- (void)identify:(SEGIdentifyPayload *)payload
{
    if (!payload.userId) return;
    [self.ADBMobile setUserIdentifier:payload.userId];
    SEGLog(@"[ADBMobile setUserIdentifier:%@]", payload.userId);
}

- (void)track:(SEGTrackPayload *)payload
{
    [self realTrack:payload.event andProperties:payload.properties];
}

- (void)screen:(SEGScreenPayload *)payload
{
    NSMutableDictionary *data = [self mapContextValues:payload.properties];
    [self.ADBMobile trackState:payload.name data:data];
    SEGLog(@"[ADBMobile trackState:%@ data:%@];", payload.name, data);
}

#pragma mark - Util Functions

// All context data variables must be mapped by using processing rules,
// meaning they must be configured as a context variable in Adobe's UI
// and mapped from a Segment Property to the configured variable in Adobe
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
            // Catch the case where productIdentifier is nil
            if ([self formatProducts:obj] == nil) {
                return nil;
            }
            formattedProducts = [formattedProducts stringByAppendingString:[self formatProducts:obj]];
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

// The `&&products` variable is expected to be formated in the following order:
// `"Category;Product;Quantity;Price;eventN=X[|eventN2=X2];eVarN=merch_category[|eVarN2=merch_category2]"`
// formatProducts can take in an object from the products array:
//  @"products" : @[
//      @{
//          @"product_id" : @"2013294",
//          @"category" : @"Games",
//          @"name" : @"Monopoly: 3rd Edition",
//          @"brand" : @"Hasbros",
//          @"price" : @"21.99",
//          @"quantity" : @"1"
//      }
// And output the following : @"Games;Monopoly: 3rd Edition;1;21.99,;Games;Battleship;2;27.98"
//
// It can also format a product passed in as a top level property, for example
//      @{
//          @"product_id" : @"507f1f77bcf86cd799439011",
//          @"sku" : @"G-32",
//          @"category" : @"Food",
//          @"name" : @"Turkey",
//          @"brand" : @"Farmers",
//          @"variant" : @"Free Range",
//          @"price" : @180.99,
//          @"quantity" : @1,
//      }
//
// And output the following: @"Food;G-32;1;180.99"

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

- (void)realTrack:(NSString *)event andProperties:(NSDictionary *)properties
{
    NSDictionary *contextData;

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
    if (adobeEcommerceEvents[event]) {
        contextData = [self mapProducts:adobeEcommerceEvents[event] andProperties:properties];
        [self.ADBMobile trackAction:adobeEcommerceEvents[event] data:contextData];
        return;
    }

    NSMutableDictionary *data = [self mapContextValues:properties];
    event = [self mapEventsV2:event];
    if (!event) {
        SEGLog(@"Event must be configured in Adobe and in the EventsV2 setting in Segment before sending.");
        return;
    }

    [self.ADBMobile trackAction:event data:data];
    SEGLog(@"[ADBMobile trackAction:%@ data:%@];", event, data);
}

@end
