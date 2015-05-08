//
//  NSService.h
//  Staff5Personal
//
//  Created by Mansour Boutarbouch Mhaimeur on 30/09/13.
//  Copyright (c) 2013 Smart & Artificial Technologies. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef NSSERVICE_DEBUG
	#ifdef DEBUG
		#if DEBUG
			#define NSSERVICE_DEBUG 0
		#else
			#define NSSERVICE_DEBUG 0
		#endif
	#else
		#define NSSERVICE_DEBUG 0
	#endif
#endif

/**
	Android-equivalent of Service
  @see http://stackoverflow.com/questions/18329653/ios-equivalent-to-android-service?answertab=active#tab-top
 */
@interface NSService : NSObject

#pragma mark - properties

@property (nonatomic) UIBackgroundTaskIdentifier backgroundTask;
@property (nonatomic) NSInteger frequency;
@property (nonatomic) NSInteger timeToLive;
@property (nonatomic, strong) NSTimer *updateTimer;
@property (nonatomic, strong) NSString *serviceName;
@property (nonatomic) BOOL runOnExpiredHandler;
@property (nonatomic) BOOL applicationFromBackground;
@property (nonatomic) BOOL serviceIsRunning;

#pragma mark - initialization

- (id) initWithFrequency: (NSInteger) seconds;

#pragma mark - service main methods

/**
	start the background service
 */
- (void) startService;

/**
	Stop the background service
 */
- (void) stopService;

- (void) stopExpiredService;

/**
 //Español //Sobreescribir este metodo para hacer lo que quieras
 //English //Override this method to do whatever you want
 */
- (void) doInBackground;

- (void) checkInfoPlist;

/**
 @see http://stackoverflow.com/questions/9530075/ios-access-app-info-plist-variables-in-code
 @see https://developer.apple.com/library/ios/documentation/General/Reference/InfoPlistKeyReference/Introduction/Introduction.html#//apple_ref/doc/uid/TP40009247
 */
- (id) getAppInfoProperty:(NSString*)prefName;

@end
