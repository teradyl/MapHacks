//
//  GMapsController.m
//  MapHacks
//
//  Created by Dylan Harris on 10/7/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import "GMapsController.h"
#import "GMSMapView+DHLockingZoom.h"

@interface GMapsController ()

@property (nonatomic, strong) GMSMapView *mapView;

@end

@implementation GMapsController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.mapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    
    [self.mapView enableLockingZoom];
    
    self.mapView.settings.rotateGestures = NO;
    self.mapView.settings.tiltGestures = NO;
    
    //setting this property instead of the enableLockingZoom category can also lock zoom
    //self.mapView.settings.allowScrollGesturesDuringRotateOrZoom = NO;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
