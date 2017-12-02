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

    [self.ADBMobile collectLifecycleData];

    return self;
}

- (instancetype)initWithSettings:(NSDictionary *)settings andADBMobile:(id _Nullable)ADBMobile
{
    if (self = [super init]) {
        self.settings = settings;
        self.ADBMobile = ADBMobile;
    }

    [self.ADBMobile collectLifecycleData];

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

- (void)realTrack:(NSString *)event andProperties:(NSDictionary *)properties
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
    if (adobeEcommerceEvents[event]) {
        NSDictionary *contextData = [self mapProducts:adobeEcommerceEvents[event] andProperties:properties];
        [self.ADBMobile trackAction:adobeEcommerceEvents[event] data:contextData];
        SEGLog(@"[ADBMobile trackAction:%@ data:%@];", event, contextData);
        return;
    }

    event = [self mapEventsV2:event];
    if (!event) {
        SEGLog(@"Event must be configured in Adobe and in the EventsV2 setting in Segment before sending.");
        return;
    }
    NSDictionary *contextData = [self mapContextValues:properties];
    [self.ADBMobile trackAction:event data:contextData];
    SEGLog(@"[ADBMobile trackAction:%@ data:%@];", event, contextData);
}

@end
