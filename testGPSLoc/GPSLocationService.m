/*
 @file GPSLocationService.m
 @author Fabio Cigliano
 @date 03/10/13.
 @copy Copyright (c) 2013 Fabio Cigliano. All rights reserved.
 @see http://stackoverflow.com/questions/11417837/running-background-services-in-ios
 @see http://stackoverflow.com/questions/18329653/ios-equivalent-to-android-service?answertab=active#tab-top
 @see https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
 */

#import "GPSLocationService.h"

@interface GPSLocationService() {
}

@property (nonatomic, strong) CLLocationManager* locationManager;

@property (nonatomic) BOOL askedPermissionToTheUser;
@property (nonatomic) BOOL deferringUpdates;

@property (nonatomic) CLLocation* lastLocation;

-(void)notification:(NSString*)text;

@end

@implementation GPSLocationService

#pragma mark - NSService methods

- (id)init {
	self = [super init];
	if(self) {
		self.frequency = 30;
	}
	return self;
}

- (id)initWithFrequency:(NSInteger)seconds {
	self = [super initWithFrequency:seconds];
	if(self) {
		self.timeToLive = 10 * 60; // 10 minuti
	}
	return self;
}

- (void)startService {
	[super startService];
	
	if(![self locationManager]) {
		self.locationManager = [[CLLocationManager alloc] init];
		[self.locationManager setDelegate:self];
	}
	
	if( (![self askedPermissionToTheUser] || [CLLocationManager locationServicesEnabled]) && [self locationManager] ) {
		
#if GPSLOCSERVICE_DEBUG
		NSLog(@"%@ starting location service",[self class]);
#endif
		
		self.locationManager.distanceFilter = 50;
		self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
//		[self.locationManager startMonitoringSignificantLocationChanges];
		[self.locationManager startUpdatingLocation];
		
		if(![self askedPermissionToTheUser]) {
			[self setAskedPermissionToTheUser:YES];
		}
		
	} else {
#if GPSLOCSERVICE_DEBUG
		NSLog(@"%@ cannot start location service",[self class]);
#endif
	}
	
#if GPSLOCSERVICE_DEBUG
	NSLog(@"locationHistory: %@",self.lastLocation);
#endif
	
}

- (void)stopService {
	[super stopService];
	
	NSLog(@"%@ stopping location service",[self class]);
//	[[self locationManager] stopMonitoringSignificantLocationChanges];
	[[self locationManager] stopUpdatingLocation];
	
}

- (void)stopExpiredService {
	[self notification:[NSString stringWithFormat:@"stopping %@ because is expired!", self.serviceName]];
	[super stopExpiredService];
}

- (void)doInBackground {
	[super doInBackground];
	
	if (!self.deferringUpdates) {
		self.deferringUpdates = YES;
		[self.locationManager allowDeferredLocationUpdatesUntilTraveled:(CLLocationDistance)100 timeout:(NSTimeInterval)100000];
	}
}

- (void) checkInfoPlist {
	[super checkInfoPlist];
	// https://developer.apple.com/library/ios/documentation/userexperience/conceptual/LocationAwarenessPG/CoreLocation/CoreLocation.html
	NSString* prefName = @"UIRequiredDeviceCapabilities";
	NSArray* pref = [self getAppInfoProperty:prefName];
//	NSLog(@"preference %@",pref);
	if( pref && ![pref containsObject:@"location-services"] ) {
		NSLog(@"%@ you should set \"location-services\" preference in %@ %@",[self class],prefName,pref);
	}
	if( pref && ![pref containsObject:@"gps"] ) {
		NSLog(@"%@ you should set \"gps\" preference in %@ %@",[self class],prefName,pref);
	}
	// https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Articles/iPhoneOSKeys.html#//apple_ref/doc/plist/info/UIBackgroundModes
	prefName = @"UIBackgroundModes";
	pref = [self getAppInfoProperty:prefName];
	if( pref && ![pref containsObject:@"location"] ) {
		NSLog(@"%@ you should set \"location\" preference in %@ %@",[self class],prefName,pref);
	}
}

#pragma mark - properties

- (BOOL)askedPermissionToTheUser {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	BOOL ris = [defaults boolForKey:@"GPSLocationService_askedPermissionToTheUser"];
	if(ris==NO) {
		return false;
	}
	return ris;
}

- (void)setAskedPermissionToTheUser:(BOOL)askedPermissionToTheUser {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setBool:askedPermissionToTheUser forKey:@"GPSLocationService_askedPermissionToTheUser"];
	[defaults synchronize];
}

- (CLLocation *)lastLocation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	return [defaults rm_customObjectForKey:@"GPSLocationService_locationHistory"];
}

- (void)setLastLocation:(CLLocation *)lastLocation {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	// http://stackoverflow.com/questions/2315948/how-to-store-custom-objects-in-nsuserdefaults
	[defaults rm_setCustomObject:lastLocation forKey:@"GPSLocationService_locationHistory"];
	[defaults synchronize];
	
	
	if( [self delegate] && [[self delegate] respondsToSelector:@selector(locationUpdated:inBackgroundMode:)] ) {
		[[self delegate] locationUpdated:lastLocation inBackgroundMode:self.applicationFromBackground];
	}
	
	if( [self applicationFromBackground] ) {
		[self notification:[@"updated location to " stringByAppendingString:[[self lastLocation] description]]];
	}
	
}

- (CLLocation *)location {
	return self.lastLocation;
}

#pragma mark - location methods

// Delegate method from the CLLocationManagerDelegate protocol.
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	
#if GPSLOCSERVICE_DEBUG
	NSLog(@"%@ locationManager:didUpdateLocations %@",[self class], locations);
#endif
	// If it's a relatively recent event, turn off updates to save power.
	CLLocation* location = [locations lastObject];
	NSDate* eventDate = location.timestamp;
	NSTimeInterval howRecent = [eventDate timeIntervalSinceNow];
	if(abs(howRecent) < 15.0) {
		// If the event is recent, do something with it.
#if GPSLOCSERVICE_DEBUG
		NSLog(@"latitude %+.6f, longitude %+.6f\n", location.coordinate.latitude, location.coordinate.longitude);
#endif
		self.lastLocation = location;
	}
//	if( location ) {
//		self.lastLocation = location;
//	}
	
	// Defer updates until the user hikes a certain distance
	// or when a certain amount of time has passed.
	if (!self.deferringUpdates) {
		[self.locationManager allowDeferredLocationUpdatesUntilTraveled:(CLLocationDistance)1000 timeout:(NSTimeInterval)100000];
		self.deferringUpdates = YES;
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"%@ locationManager:didFailWithError %@",[self class], error);
	self.deferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error {
	NSLog(@"%@ locationManager:didFinishDeferredUpdatesWithError %@",[self class], error);
	self.deferringUpdates = NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	if( status != kCLAuthorizationStatusAuthorized ) {
		self.askedPermissionToTheUser = NO;
	}
}

- (void)locationManagerDidPauseLocationUpdates:(CLLocationManager *)manager {
	NSLog(@"%@ locationManagerDidPauseLocationUpdates",[self class]);
}

-(void)locationManagerDidResumeLocationUpdates:(CLLocationManager *)manager {
	NSLog(@"%@ locationManagerDidResumeLocationUpdates",[self class]);
}

- (BOOL)locationManagerShouldDisplayHeadingCalibration:(CLLocationManager *)manager {
	NSLog(@"%@ locationManagerShouldDisplayHeadingCalibration",[self class]);
	return YES;
}

-(void)notification:(NSString*)text {
	UILocalNotification *localNotif = [[UILocalNotification alloc] init];
	if (localNotif == nil)
		return;
	
	localNotif.fireDate = [[NSDate date] dateByAddingTimeInterval:1];
	localNotif.timeZone = [NSTimeZone defaultTimeZone];
	
	// Notification details
	localNotif.alertBody = text;
	
	// Set the action button
	localNotif.alertAction = @"View";
	localNotif.soundName = UILocalNotificationDefaultSoundName;
	localNotif.applicationIconBadgeNumber = -1;
	
	// Specify custom data for the notification
	NSDictionary *infoDict = [NSDictionary dictionaryWithObject:@"someValue" forKey:@"someKey"];
	localNotif.userInfo = infoDict;
	
	// Schedule the notification
	[[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
}

@end
