//
//  GMSMapView+DHLockingZoom.m
//  MapHacks
//
//  Created by Dylan Harris on 9/28/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import "GMSMapView+DHLockingZoom.h"
#import <objc/runtime.h>

NSString const *panKeyGoogle = @"panRecognizerDHGoog";
NSString const *pinchKeyGoogle = @"pinchRecognizerDHGoog";
NSString const *tapZoomOutKeyGoogle = @"tapZoomOutRecognizerDHGoog";
NSString const *tapZoomInKeyGoogle = @"tapZoomInRecognizerDHGoog";
NSString const *doneZoomingBlockKeyDHGoog = @"doneZoomingBlockKeyDHGoog";
NSString const *mapPanningBlockKeyDHGoog = @"mapPanningBlockKeyDHGoog";

@implementation GMSMapView (DHLockingZoom)

- (void)enableLockingZoom
{
    if(![self hasSetupGestureRecognizers]) {
        [self setupGestureRecognizers];
    }
    
    self.settings.zoomGestures = NO;
    
    [self addGestureRecognizer:self.panRecognizer];
    [self addGestureRecognizer:self.pinchRecognizer];
    [self addGestureRecognizer:self.tapZoomInRecognizer];
    [self addGestureRecognizer:self.tapZoomOutRecognizer];

}

- (void)disableLockingZoom
{
    self.settings.zoomGestures = YES;
    
    [self removeGestureRecognizer:self.panRecognizer];
    [self removeGestureRecognizer:self.pinchRecognizer];
    [self removeGestureRecognizer:self.tapZoomInRecognizer];
    [self removeGestureRecognizer:self.tapZoomOutRecognizer];
}

- (BOOL)hasSetupGestureRecognizers
{
    if(self.pinchRecognizer && self.tapZoomInRecognizer && self.tapZoomOutRecognizer) {
        return YES;
    }
    else {
        return NO;
    }
}

- (void)setupGestureRecognizers
{
    //setup gesture recognizers manually
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(mapPanned:)];
    self.panRecognizer.delegate = self;
    
    self.pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(mapPinched:)];
    self.pinchRecognizer.delegate = self;
    
    self.tapZoomInRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapDoubleTapped:)];
    self.tapZoomInRecognizer.delegate = self;
    self.tapZoomInRecognizer.numberOfTapsRequired = 2;
    self.tapZoomInRecognizer.numberOfTouchesRequired = 1;
    
    self.tapZoomOutRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mapTwoFingerTapped:)];
    self.tapZoomOutRecognizer.delegate = self;
    self.tapZoomOutRecognizer.numberOfTouchesRequired = 2;
    self.tapZoomOutRecognizer.numberOfTapsRequired = 1;
}

#pragma mark Custom zoom gestures

- (void)mapPanned:(UIPanGestureRecognizer *)panRecognizer
{
    [self mapPanningBlock];
}

- (void)mapPinched:(UIPinchGestureRecognizer *)pinchRecognizer
{
    static GMSCameraPosition *originalCamPosition;
    if (pinchRecognizer.state == UIGestureRecognizerStateBegan){
        //disable scroll (aka pan) gestures temporarily to lock the pinch zoom on center
        self.settings.scrollGestures = NO;
        
        //disable panRecognizer here so it can be in sync with the scrollGestures
        self.panRecognizer.enabled = NO;
        
        originalCamPosition = self.camera;
    } else if (pinchRecognizer.state == UIGestureRecognizerStateEnded) {
        //re-enable scrolling (panning) recognizers
        self.settings.scrollGestures = YES;
        self.panRecognizer.enabled = YES;
    } else {
        //google maps zoom is on an exponential scale, so we have to change our linear pinch scale to a logarithmic scale
        float zoomDelta = originalCamPosition.zoom + log2(pinchRecognizer.scale);
        self.camera = [GMSCameraPosition cameraWithTarget:self.camera.target zoom:zoomDelta];
    }
    
    [self doneZoomingBlock];
}

- (void)mapDoubleTapped:(UITapGestureRecognizer *)doubleTapRecognizer
{
    double zoomIncrease = 1.3;
    [self animateToZoom:self.camera.zoom+zoomIncrease];
    [self doneZoomingBlock];
}

- (void)mapTwoFingerTapped:(UITapGestureRecognizer *)doubleFingerTapRecognizer
{
    double zoomDecrease = 1.3;
    [self animateToZoom:self.camera.zoom-zoomDecrease];
    [self doneZoomingBlock];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    //by returning YES, this allows one specific gesture to work: if you pan with 1 finger and add a 2nd finger and start pinching to zoom without lifting your 1st finger
    //if you return NO, once you start panning you won't be able to zoom until you lift your finger
    
    if((gestureRecognizer == self.pinchRecognizer && otherGestureRecognizer == self.tapZoomOutRecognizer) ||
       (gestureRecognizer == self.tapZoomOutRecognizer && otherGestureRecognizer == self.pinchRecognizer)) {
        //need this case to be NO so after a pinch zoom it doesn't detect a 2 finger tap and zoom out
        return NO;
    }
    
    if((gestureRecognizer == self.panRecognizer && otherGestureRecognizer == self.tapZoomOutRecognizer) ||
       (gestureRecognizer == self.tapZoomOutRecognizer && otherGestureRecognizer == self.panRecognizer)) {
        //need this case to be NO so 2 finger tap doesn't interact with panning
        return NO;
    }
    
    if((gestureRecognizer == self.panRecognizer && otherGestureRecognizer == self.tapZoomInRecognizer) ||
       (gestureRecognizer == self.tapZoomInRecognizer && otherGestureRecognizer == self.panRecognizer)) {
        //need this case to be NO so double tap in doesn't interact with panning
        return NO;
    }
    
    return YES;
}

- (void)doneZooming
{
    if(self.doneZoomingBlock) {
        self.doneZoomingBlock();
    }
}

- (void)mapPanning
{
    if(self.mapPanningBlock) {
        self.mapPanningBlock();
    }
}

#pragma mark Associated objects to make properties within MapViewCategory
- (void)setPanRecognizer:(UIPinchGestureRecognizer *)panRecognizer
{
    objc_setAssociatedObject(self, &panKeyGoogle, panRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPanGestureRecognizer *)panRecognizer
{
    return objc_getAssociatedObject(self, &panKeyGoogle);
}

- (void)setPinchRecognizer:(UIPinchGestureRecognizer *)pinchRecognizer
{
    objc_setAssociatedObject(self, &pinchKeyGoogle, pinchRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIPinchGestureRecognizer *)pinchRecognizer
{
    return objc_getAssociatedObject(self, &pinchKeyGoogle);
}

- (void)setTapZoomOutRecognizer:(UITapGestureRecognizer *)tapZoomOutRecognizer
{
    objc_setAssociatedObject(self, &tapZoomOutKeyGoogle, tapZoomOutRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITapGestureRecognizer *)tapZoomOutRecognizer
{
    return objc_getAssociatedObject(self, &tapZoomOutKeyGoogle);
}

- (void)setTapZoomInRecognizer:(UITapGestureRecognizer *)tapZoomInRecognizer
{
    objc_setAssociatedObject(self, &tapZoomInKeyGoogle, tapZoomInRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITapGestureRecognizer *)tapZoomInRecognizer
{
    return objc_getAssociatedObject(self, &tapZoomInKeyGoogle);
}

- (void)setDoneZoomingBlock:(void(^)())doneZoomingBlock
{
    objc_setAssociatedObject(self, &doneZoomingBlockKeyDHGoog, doneZoomingBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void(^)())doneZoomingBlock
{
    return objc_getAssociatedObject(self, &doneZoomingBlockKeyDHGoog);
}

- (void)setMapPanningBlock:(void (^)())mapPanningBlock
{
    objc_setAssociatedObject(self, &mapPanningBlockKeyDHGoog, mapPanningBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void(^)())mapPanningBlock
{
    return objc_getAssociatedObject(self, &mapPanningBlockKeyDHGoog);
}

@end

