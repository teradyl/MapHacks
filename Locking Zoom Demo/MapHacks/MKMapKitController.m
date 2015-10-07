//
//  MKMapKitController.m
//  MapHacks
//
//  Created by Dylan Harris on 10/7/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import "MKMapKitController.h"
#import "MKMapView+DHLockingZoom.h"

@interface MKMapKitController ()

@property(nonatomic, strong) MKMapView *mapView;

@end

@implementation MKMapKitController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    
    [self.mapView enableLockingZoom];
    
    [self.mapView setDonePinchingBlock:^{
        NSLog(@"done pinching");
    }];
    
    [self.mapView setDoneZoomingBlock:^{
        NSLog(@"done zooming");
    }];
}


- (void)drawRouteOverlayWithSource:(MKMapItem*)source dest:(MKMapItem*)dest
{
    //to create MKMapItem
    //    [[MKMapItem alloc] initWithPlacemark:
    //                          [[MKPlacemark alloc] initWithCoordinate:*coord2Dhere*
    //                                                addressDictionary:nil]];
    
    
    MKDirectionsRequest *request = [[MKDirectionsRequest alloc] init];
    
    request.source = source;
    request.destination = dest;
    
    MKDirections *directions = [[MKDirections alloc] initWithRequest:request];
    
    [directions calculateDirectionsWithCompletionHandler:
     ^(MKDirectionsResponse *response, NSError *error) {
         if (error) {
             NSLog(@"couldn't get route. not much you can do about this.");
         } else {
             //success!
             NSMutableArray *tempRoutes = [NSMutableArray array];
             for (MKRoute *route in response.routes)
             {
                 [tempRoutes addObject:route];
                 [self.mapView addOverlay:route.polyline level:MKOverlayLevelAboveRoads];
             }
             
             //if route lines get complicated and redrawn often, could be beneficial
             //to cache MKMapItems that succeeded here and don't make these calls if the MKMapItems are the same
         }
     }];
}

- (void)manipulateRouteLine:(MKPolyline*)polyline
{
    NSUInteger pointCount = polyline.pointCount;
    
    //allocate a C array to hold this many points/coordinates...
    CLLocationCoordinate2D *routeCoordinates = malloc(pointCount * sizeof(CLLocationCoordinate2D));
    
    //get the coordinates and store in routeCoordinates
    [polyline getCoordinates:routeCoordinates range:NSMakeRange(0, pointCount)];
    
    //get to some serious programming
    
    //loop through coords, check intersections with other polygons, remove points, add points
    
    //eventually you will have to remove all the old overlays from the map and re-add all your new manipulated route lines as new overlays
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
