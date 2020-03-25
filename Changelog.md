Change Log
==========

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
