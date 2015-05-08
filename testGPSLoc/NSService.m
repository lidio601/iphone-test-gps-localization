//
//  NSService.m
//  Staff5Personal
//
//  Created by Mansour Boutarbouch Mhaimeur on 30/09/13.
//  Copyright (c) 2013 Smart & Artificial Technologies. All rights reserved.
//

#import "NSService.h"

#import "AppDelegate.h"

@interface NSService() {
}

@property (nonatomic, strong) NSDate* timeStart;

- (void) startBackgroundTask;
- (void) endBackgroundTask;

@end

@implementation NSService

#pragma mark - properties

@synthesize frequency;
@synthesize serviceName;

#pragma mark - initialization

- (id)init {
#if NSSERVICE_DEBUG
	NSLog(@"%@ setting default frequency to 30 seconds",[self class]);
#endif
	return [self initWithFrequency:30];
}

-(id)initWithFrequency: (NSInteger) seconds{
	self = [super init];
	if(self) {
#if NSSERVICE_DEBUG
		NSLog(@"%@ init with frequency %ld seconds",[self class],(long)seconds);
#endif
		self.frequency = seconds;
		self.timeToLive = 60*1; // 10 min
		[self checkInfoPlist];
	}
	return self;
}

- (void)dealloc {
#if NSSERVICE_DEBUG
	NSLog(@"%@ dealloc",[self class]);
#endif
}

#pragma mark - service main methods

- (void)startService {
#if NSSERVICE_DEBUG
	NSLog(@"%@ startService",[self class]);
#endif
	
	// http://stackoverflow.com/questions/4846822/iphone-use-of-background-foreground-methods-in-appdelegate
	[self setApplicationFromBackground:([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)];
	
	[self startBackgroundTask];
	
	self.serviceIsRunning = true;
}

- (void)doInBackground {
	
	// http://stackoverflow.com/questions/4846822/iphone-use-of-background-foreground-methods-in-appdelegate
	[self setApplicationFromBackground:([[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground)];
	
#if NSSERVICE_DEBUG
//	NSLog(@"doing Background Work: %@ (sleeping for 3 seconds) inBackground %i",[self serviceName],[self applicationFromBackground]);
//	[NSThread sleepForTimeInterval:3.0];
#endif
	
	if( ![self applicationFromBackground] ) {
		self.timeStart = [[NSDate alloc] init];
#if NSSERVICE_DEBUG
		NSLog(@"%@ service started at %@",[self class],self.timeStart);
#endif
	}
	
#if NSSERVICE_DEBUG
	NSLog(@"%@ doInBackground inBackground %i backgrondRefreshTime %d backgroundtimeRemaining %f",[self class],[self applicationFromBackground],[[UIApplication sharedApplication] backgroundRefreshStatus],[[UIApplication sharedApplication] backgroundTimeRemaining]);
#endif
	
	if( [self applicationFromBackground] && [self timeStart] && ABS([[self timeStart] timeIntervalSinceNow]) >= [self timeToLive] ) {
#if NSSERVICE_DEBUG
		NSLog(@"%@ service expired from %@ because of %f >= %d ",[self class],self.timeStart,ABS([[self timeStart] timeIntervalSinceNow]),[self timeToLive]);
#endif
		[self stopExpiredService];
	}
	
}

- (void)stopExpiredService {
	[self stopService];
}

- (void)stopService {
#if NSSERVICE_DEBUG
	NSLog(@"%@ stopService",[self class]);
#endif
	[self.updateTimer invalidate];
	self.updateTimer = nil;
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
	self.backgroundTask = UIBackgroundTaskInvalid;
	self.serviceIsRunning = false;
}

#pragma mark - hidden internal methods

- (void) startBackgroundTask {
#if NSSERVICE_DEBUG
	NSLog(@"%@ start Background Task",[self class]);
#endif
	if( ![self applicationFromBackground] ) {
		self.timeStart = [[NSDate alloc] init];
#if NSSERVICE_DEBUG
		NSLog(@"%@ service started at %@",[self class],self.timeStart);
#endif
	} else {
		if( [self timeStart] && ABS([[self timeStart] timeIntervalSinceNow]) >= [self timeToLive] ) {
//#if NSSERVICE_DEBUG
			NSLog(@"%@ service expired from %@ because of %f >= %d ",[self class],self.timeStart,ABS([[self timeStart] timeIntervalSinceNow]),[self timeToLive]);
//#endif
			return;
		}
	}
	self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
																											target:self
																										selector:@selector(doInBackground)
																										userInfo:nil
																										 repeats:YES];
	self.backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
//#if NSSERVICE_DEBUG
		NSLog(@"%@ Terminating expider service %@ %i",[self class],[self serviceName],self.runOnExpiredHandler);
//#endif
		[self endBackgroundTask];
//		if( self.runOnExpiredHandler == true ) {
//			NSLog(@"%@ re-starting Background Task",[self class]);
//			[self startBackgroundTask];
//		}
	}];
}

- (void) endBackgroundTask {
	[self.updateTimer invalidate];
	self.updateTimer = nil;
	[[UIApplication sharedApplication] endBackgroundTask:self.backgroundTask];
	self.backgroundTask = UIBackgroundTaskInvalid;
#if NSSERVICE_DEBUG
	NSLog(@"%@ re-starting Background Task",[self class]);
#endif
	[self startBackgroundTask];
}

- (id) getAppInfoProperty:(NSString*)prefName {
	// http://stackoverflow.com/questions/9530075/ios-access-app-info-plist-variables-in-code
	// https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009247
	id pref = [[NSBundle mainBundle] objectForInfoDictionaryKey:prefName];
//	NSLog(@"pref %@ = %@",prefName,pref);
	return pref;
}

- (void) checkInfoPlist {
#if NSSERVICE_DEBUG
	NSLog(@"%@ checkInfoPlist",[self class]);
#endif
}

@end
