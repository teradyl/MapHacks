//
//  MKMapView+LockingZoom.h
//  MapHacks
//
//  Created by Dylan Harris on 9/27/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MapKit;

@interface MKMapView (DHLockingZoom) <UIGestureRecognizerDelegate>

@property(nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer *tapZoomOutRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer* tapZoomInRecognizer;

- (void)enableLockingZoom;
- (void)disableLockingZoom;

@property(nonatomic, strong) void(^donePinchingBlock)();
@property(nonatomic, strong) void(^doneZoomingBlock)();

//add properties if you want to limit zoom level further

@end
