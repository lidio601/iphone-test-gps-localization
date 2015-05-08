//
//  ViewController.m
//  testGPSLoc
//
//  Created by Fabio Cigliano on 03/10/13.
//  Copyright (c) 2013 Fabio Cigliano. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (NSMutableArray *)locationlist {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSArray* ris = [defaults objectForKey:@"GPSLocationTestService_locations"];
	if(!ris) {
		return [[NSMutableArray alloc] init];
	}
	return [ris mutableCopy];
}

- (void)setLocationlist:(NSMutableArray *)locationlist {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setObject:[locationlist copy] forKey:@"GPSLocationTestService_locations"];
	[defaults synchronize];
	NSLog(@"sync");
}

- (void) addLocation:(CLLocation*)location {
	if( [location coordinate].latitude <= 43 || [location coordinate].latitude >= 47 || [location coordinate].longitude <= 8 || [location coordinate].longitude >= 10 ) {
		return;
	}
	if( !CLLocationCoordinate2DIsValid([location coordinate]) ) {
		NSLog(@"dropping non valid coordinate %@",location);
		return;
	}
	NSMutableArray* a = self.locationlist;
	if( [a count] > 0 ) {
		CLLocation* lastLoc = [self locationAt:[a count]-1];
		if( CLCOORDINATES_EQUAL([lastLoc coordinate],[location coordinate],0.001) && fabs( [[lastLoc timestamp] timeIntervalSinceNow] ) < 10.0 ) {
			NSLog(@"droppping duplicate coordinate %@",location);
			return;
		}
	}
//	[a addObject:location];
	NSData* encoded = [NSUserDefaults rm_encodeObject:location];
	[a addObject:encoded];
	self.locationlist = a;
	
	if( [[self locationlist] count] <= 5 ) {
		self.slider.hidden = YES;
	} else {
		self.slider.hidden = NO;
		self.slider.maximumValue = [[self locationlist] count];
		self.slider.minimumValue = 0;
//		self.slider.value = [[self locationlist] count] - 5;
	}
	
	[self drawPath];
	
}

- (CLLocation*) locationAt:(NSUInteger)index {
//	if( index < 0 ) return nil;
	NSMutableArray* a = [self locationlist];
	if( index >= [a count] )	return nil;
	NSData* encoded = [a objectAtIndex:index];
	return [NSUserDefaults rm_decodeObject:encoded];
}

@synthesize testService = _testService;

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	
//	self.testService = [[NSService alloc] init];
//	self.testService.serviceName = @"my Test Service";
//	self.testService.runOnExpiredHandler = YES;
//	[self.testService startService];
	
	self.testService = [[GPSLocationService alloc] init];
	self.testService.delegate = self;
	self.testService.serviceName = @"my Test Location Service";
	self.testService.runOnExpiredHandler = true;
	[self.testService startService];
	
	NSLog(@"self locations %d",[[self locationlist] count]);
	if( [[self locationlist] count] <= 5 ) {
		self.slider.hidden = YES;
	} else {
		self.slider.hidden = NO;
		self.slider.maximumValue = [[self locationlist] count];
		self.slider.minimumValue = 0;
		self.slider.value = [[self locationlist] count] - 5;
	}
}

- (void)dealloc {
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)viewDidAppear:(BOOL)animated {
	self.map.showsUserLocation = YES;
	self.map.zoomEnabled   = YES;
	self.map.pitchEnabled  = YES;
	self.map.scrollEnabled = YES;
//	[self.map setCamera:[MKMapCamera cameraLookingAtCenterCoordinate:CLLocationCoordinate2DMake(0,0) fromEyeCoordinate:CLLocationCoordinate2DMake(45,39) eyeAltitude:1000000]];
	self.map.userTrackingMode = MKUserTrackingModeFollow;
	if( [self.testService location] ) {
		[self.map setCenterCoordinate:[[self.testService location] coordinate]];
		self.label.text = [[self.testService location] description];
	}
	if(! [[self testService] serviceIsRunning] ) {
		[[self testService] startService];
	}
}

- (void) locationUpdated:(CLLocation*)location inBackgroundMode:(BOOL)applicationInBackground {
	NSLog(@"%@ locationUpdated:inBackgroundMode: %@ %i",[self class],location,applicationInBackground);
	if( !applicationInBackground ) {
		[self.map setCenterCoordinate:location.coordinate];
	} else {
		NSLog(@"location in background %@",location);
	}
	[self addLocation:location];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
	[[self testService] stopService];
}

- (IBAction)sliderChange:(id)sender {
	[self drawPath];
}

-(void) drawPath {
//	NSString* filePath = [[NSBundle mainBundle] pathForResource:@”route” ofType:@”csv”];
//	NSString* fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
//	NSArray* pointStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	CGMutablePathRef path = CGPathCreateMutable();
	BOOL startingPoint = YES;
	CGPoint cgpoint;
	NSArray* pointStrings = self.locationlist;
	
	MKMapPoint northEastPoint;
	MKMapPoint southWestPoint;
	
	int len = pointStrings.count;
	int idx = 0;
	int i = 0;
	
	if(len > 5) {
		len = MIN(self.slider.value+5+1,pointStrings.count);
		idx = self.slider.value;
	}
	
	MKMapPoint* pointArr = malloc(sizeof(CLLocationCoordinate2D) * len);
	NSLog(@"from %d to %d",idx,len);
	for(; idx < len; idx++) {
		
//		NSString* currentPointString = [pointStrings objectAtIndex:idx];
//		NSArray* latLonArr = [currentPointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
		
		CLLocation* location = [self locationAt:idx];

//		CLLocationDegrees latitude  = [location coordinate].latitude;
//		CLLocationDegrees longitude = [location coordinate].longitude;
		
		CLLocationCoordinate2D coordinate = [location coordinate];
		
		NSLog(@"point %d %f %f",idx,coordinate.latitude,coordinate.longitude);

		MKMapPoint point = MKMapPointForCoordinate(coordinate);

		if (i == 0) {
			northEastPoint = point;
			southWestPoint = point;
		} else {
			if (point.x > northEastPoint.x) northEastPoint.x = point.x;
			if(point.y > northEastPoint.y)  northEastPoint.y = point.y;
			if (point.x < southWestPoint.x) southWestPoint.x = point.x;
			if (point.y < southWestPoint.y) southWestPoint.y = point.y;
		}
		pointArr[i++] = point;
		
//		cgpoint = [self.map convertCoordinate:coordinate toPointToView:self.map];
//		
//		//  Add the current point to the path representing this route
//		if (startingPoint) {
//			CGPathMoveToPoint(path, NULL, cgpoint.x, cgpoint.y);
//		} else {
//			CGPathAddLineToPoint(path, NULL, cgpoint.x, cgpoint.y);
//		}
		
	}
	
//	//  Close the subpath and add a line from the last point to the first point.
//	CGPathCloseSubpath(path);
//	self.overlayView.path = path;
	
	if( self.routeLine ) {
		[self.map removeOverlay:self.routeLine];
		self.routeLine = nil;
	}
	
	self.routeLine = [MKPolyline polylineWithPoints:pointArr count:len];

	self.routeRect = MKMapRectMake(
																 southWestPoint.x-0.1,
																 southWestPoint.y-0.1,
																 (northEastPoint.x - southWestPoint.x)+0.2,
																 (northEastPoint.y - southWestPoint.y)+0.2
																 );
	
	[self.map addOverlay:self.routeLine];
	
	[[self map] setVisibleMapRect:self.routeRect edgePadding:UIEdgeInsetsMake(10, 10, 10, 10) animated:YES];
//	self.map.visibleMapRect = self.routeRect;
	
	free(pointArr);
	
//	- (MKOverlayView *)mapView:(MKMapView *)mapView viewForOverlay:(id )overlay {
//	MKOverlayView* overlayView = nil;
	
//	if(!self.overlayView) {
//		//if we have not yet created an overlay view for this overlay, create it now.
//		self.overlayView = [[MKOverlayPathView alloc] init];
//		[self.map addOverlay:self.overlayView];
//		MKPolylineRenderer* routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:self.routeLine];
//		routeLineView.fillColor = [UIColor redColor];
//		routeLineView.strokeColor = [UIColor redColor];
//		routeLineView.lineWidth = 3;
//		
//	}
}

// =============================================================================
#pragma mark - MKMapViewDelegate

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView
            rendererForOverlay:(id<MKOverlay>)overlay
{
	MKPolylineRenderer *renderer = [[MKPolylineRenderer alloc] initWithOverlay:overlay];
	renderer.lineWidth = 5.0;
	renderer.strokeColor = [UIColor purpleColor];
	return renderer;
}

@end
