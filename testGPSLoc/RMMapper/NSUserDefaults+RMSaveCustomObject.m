//
//  NSUserDefaults+RMSaveCustomObject.m
//  RMMapper
//
//  Created by Roomorama on 28/6/13.
//  Copyright (c) 2013 Roomorama. All rights reserved.
//

#import "NSUserDefaults+RMSaveCustomObject.h"

@implementation NSUserDefaults (RMSaveCustomObject)

-(void)rm_setCustomObject:(id)obj forKey:(NSString *)key {
	NSData *encodedObject = [NSUserDefaults rm_encodeObject:obj];
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:encodedObject forKey:key];
	[defaults synchronize];
}

-(id)rm_customObjectForKey:(NSString *)key {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSData *encodedObject = [defaults objectForKey:key];
	id obj = [NSUserDefaults rm_decodeObject:encodedObject];
	return obj;
}

+(NSData*) rm_encodeObject:(id)myCustomObject {
	if ([myCustomObject respondsToSelector:@selector(encodeWithCoder:)] == NO) {
		NSLog(@"Error save object to NSUserDefaults. Object must respond to encodeWithCoder: message");
		return Nil;
	}
	NSData *encodedObject = [NSKeyedArchiver archivedDataWithRootObject:myCustomObject];
	return encodedObject;
}

+(id) rm_decodeObject:(id)myCustomEncodedObject {
	id obj = [NSKeyedUnarchiver unarchiveObjectWithData:myCustomEncodedObject];
	return obj;
}

@end