Change Log
==========
Version 1.6.0 *(25th June, 2020)*
-------------------------------------------
*(Supports analytics-ios 4.0.+)*
* For context data variable mappings we default to converting booleans to "true" or "false". Previously these were passed as 0/1.
* Removes trackComplete from Video Content Completed events as it incorrectly ends the session and discards subsequent HB calls.
* Adds trackComplete to Video Playback Completed events.
* Adds support to map top level properties on track calls (messageId, anonymousId, event) and on screen (name, messageId and anonymousId)
* Adds support for nested context data (non-HB) variable and context metadata (HB) mapping in context.app, context.device, context.library, os, network, and screen.  

Version 1.5.2 *(18th June, 2020)*
-------------------------------------------
Relaxes Segment Analytics library dependency.

Version 1.5.1 *(2nd June, 2020)*
-------------------------------------------
Adds support for `Video Playback Interrupted`.

Version 1.5.0 *(6th April, 2020)*
-------------------------------------------
Upgrades to use AdobeMediaSDK since AdobeVideoHeartbeatSDK is deprecated.
Fixes a bug where only `Video Playback Started` events were logged with no `ping` events  fired.

Version 1.4.3 *(3rd April, 2020)*
-------------------------------------------
Fixes app crash with null pointer assignment in `mapContextValues` function.

Version 1.4.2 *(1st April, 2020)*
-------------------------------------------
Fixes bug with Context Data Variables checking `payload.context` specifically in traits object.

Version 1.4.1 *(25th March, 2020)*
-------------------------------------------
Remove #import quote syntax to fix build errors with multiple `.xcodeproj`.
Fixes but where Segment was only looking in `payload.properties` for Context Data Variables assigned in destination settings. The the fix will now also check in `payload.context`.

Version 1.4.0 *(23th March, 2020)*
-------------------------------------------
*(Supports AdobeMobileSDK/TVOS & AdobeVideoHeartbeatSDK/TVOS)*
Adds support for tvOS.

Version 1.3.1 *(20th March, 2020)*
-------------------------------------------
Fixes bug where app crashed when `properties.publisher` not sent for Video Heartbeat events.

Version 1.3.0 *(28th February, 2020)*
-------------------------------------------
Fixes bundling issues with transitive dependency that have statically linked libraries.

Version 1.2.0 *(4th October, 2019)*
-------------------------------------------

Bump Adobe Analytics dependency to 4.18.7.

Version 1.1.1-beta *(21st December, 2017)*
-------------------------------------------
*(Supports analytics-ios 3.5.+)*

[Bug](https://github.com/segment-integrations/analytics-ios-integration-adobe-analytics/pull/32): Fix to check for heartbeatTrackingServerUrl.

Version 1.1.0-beta *(14th December, 2017)*
-------------------------------------------
*(Supports analytics-ios 3.5.+)*

Initial beta release for Adobe Video Heartbeat support.

Version 1.0.0-beta *(1st December, 2017)*
-------------------------------------------
*(Supports analytics-ios 3.5.+)*

Initial beta release.
