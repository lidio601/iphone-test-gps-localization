//
//  ViewController.h
//  testGPSLoc
//
//  Created by Fabio Cigliano on 03/10/13.
//  Copyright (c) 2013 Fabio Cigliano. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPSLocationService.h"
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <GPSLocationServiceDelegate, MKMapViewDelegate>

@property (nonatomic, strong) GPSLocationService *testService;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet MKMapView *map;

@property (nonatomic) NSMutableArray* locationlist;
- (CLLocation*) locationAt:(NSUInteger)index;
- (void) addLocation:(CLLocation*)location;

@property (weak, nonatomic) IBOutlet UISlider *slider;
- (IBAction)sliderChange:(id)sender;

@property (strong, nonatomic) MKPolyline* routeLine;
@property (nonatomic) MKMapRect routeRect;

@end
