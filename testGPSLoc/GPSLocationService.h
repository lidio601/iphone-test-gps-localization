/*
 @file GPSLocationService.h
 @author Fabio Cigliano
 @date 03/10/13.
 @copy Copyright (c) 2013 Fabio Cigliano. All rights reserved.
 @see http://stackoverflow.com/questions/11417837/running-background-services-in-ios
 There is no way to perform tasks in the background permanently at the interval of time you are requesting. You may request specific permission via the developer connection but I must warn you that you will need a very compelling argument. I included the documentation below, maybe your request falls within one of the groupings that could run permanently. Or maybe you could use one of the long running background threads and adapt it in such a way that it fulfils the task you are attempting.
 
 Directly from Apple's Documentation:
 
 Implementing Long-Running Background Tasks
 
 For tasks that require more execution time to implement, you must request specific permissions to run them in the background without their being suspended. In iOS, only specific app types are allowed to run in the background:
 
 Apps that play audible content to the user while in the background, such as a music player app
 Apps that keep users informed of their location at all times such as a navigation app
 Apps that support Voice over Internet Protocol (VoIP)
 Newsstand apps that need to download and process new content
 Apps that receive regular update from external accessories
 Apps that implement these services must declare the services they support and use system frameworks to implement the relevant aspects of those services. Declaring the services lets the system know which services you use, but in some cases it is the system frameworks that actually prevent your application from being suspended.
 @see http://stackoverflow.com/questions/18329653/ios-equivalent-to-android-service?answertab=active#tab-top
 There is no way to perform tasks in the background permanently,
 but you can use the finite-length tasks to do that, when you make a finite-length,
 this gonna run always while the app is active,
 but when you click home button,
 ios gives you only 10 min
 to perform your task and invalidate it, but it gives you a chance to make a 'invalidate handler block' where you can do last actions before finish definitely.
 So, if you use that handler block to call a finite-length task other time, you can simulate a service by run a task for 10 min and when its end, call its same for other 10 min and consequently.
 
 And in your app delegate or where you need to raise the service, you write the next line:
 
 \code{.m}
 Service myService = [[SomeService alloc] initWithFrequency: 60]; //execute doInBackground each 60 seconds
 [myService startService];
 \endcode
 And if you need to stop it:
 \code{.m}
 [myService stopService];
 \endcode
 
 @see https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
 
 */

#import <Foundation/Foundation.h>

// http://stackoverflow.com/questions/10199133/how-can-i-compare-two-cllocationcoordinate2ds-iphone-ipad
#define CLCOORDINATES_EQUAL( coord1, coord2, epsilon ) (( fabs(coord1.latitude - coord2.latitude) <= epsilon && fabs(coord1.longitude - coord2.longitude) <= epsilon ))

#define NSSERVICE_DEBUG 1

#ifndef GPSLOCSERVICE_DEBUG
	#ifdef DEBUG
		#if DEBUG
			#define GPSLOCSERVICE_DEBUG 0
		#else
			#define GPSLOCSERVICE_DEBUG 0
		#endif
		#else
			#define GPSLOCSERVICE_DEBUG 0
	#endif
#endif

#import "NSService.h"
#import <CoreLocation/CoreLocation.h>


@protocol GPSLocationServiceDelegate <NSObject>

- (void) locationUpdated:(CLLocation*)location inBackgroundMode:(BOOL)applicationInBackground;

@end

@interface GPSLocationService : NSService <CLLocationManagerDelegate>

@property (nonatomic,assign) id<GPSLocationServiceDelegate> delegate;

@property (nonatomic,readonly) CLLocation* location;

@end
