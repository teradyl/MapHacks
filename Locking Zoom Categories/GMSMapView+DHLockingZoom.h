//
//  GMSMapView+DHLockingZoom.h
//  MapHacks
//
//  Created by Dylan Harris on 9/28/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

@import GoogleMaps;

@interface GMSMapView (DHLockingZoom) <UIGestureRecognizerDelegate>

@property (nonatomic, strong) UIPanGestureRecognizer *panRecognizer;
@property(nonatomic, strong) UIPinchGestureRecognizer *pinchRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer *tapZoomOutRecognizer;
@property(nonatomic, strong) UITapGestureRecognizer* tapZoomInRecognizer;

- (void)enableLockingZoom;
- (void)disableLockingZoom;

@property(nonatomic, strong) void(^doneZoomingBlock)();
@property(nonatomic, strong) void(^mapPanningBlock)();

@end
