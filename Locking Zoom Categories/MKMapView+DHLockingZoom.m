//
//  MKMapView+LockingZoom.m
//  MapHacks
//
//  Created by Dylan Harris on 9/27/15.
//  Copyright (c) 2015 Dylan Harris. All rights reserved.
//

#import "MKMapView+DHLockingZoom.h"
#import <objc/runtime.h>

NSString const *pinchKey = @"pinchRecognizerDH";
NSString const *tapZoomOutKey = @"tapZoomOutRecognizerDH";
NSString const *tapZoomInKey = @"tapZoomInRecognizerDH";
NSString const *donePinchingBlockKeyDH = @"donePinchingBlockKeyDH";
NSString const *doneZoomingBlockKeyDH = @"doneZoomingBlockKeyDH";

@implementation MKMapView (DHLockingZoom)

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
    //set up gesture recognizers
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

//gesture recognizers
- (void)mapPinched:(UIPinchGestureRecognizer *)pinchRecognizer
{
    static CGFloat pinchScale;
    static MKCoordinateRegion originalRegion;
    if(pinchRecognizer.state == UIGestureRecognizerStateBegan){
        self.scrollEnabled = NO;
        pinchScale = 1;
        originalRegion = self.region;
    } else if(pinchRecognizer.state == UIGestureRecognizerStateEnded) {
        self.scrollEnabled = YES;
        [self donePinching];
        [self doneZooming];
    } else {
        double latdelta = originalRegion.span.latitudeDelta *
                            pinchScale / pinchRecognizer.scale;
        double londelta = originalRegion.span.longitudeDelta *
                            pinchScale / pinchRecognizer.scale;
        pinchScale = pinchRecognizer.scale;
        
        originalRegion.span = MKCoordinateSpanMake(latdelta, londelta);
        
        if([self spanIsOutOfBounds:originalRegion.span])
            return;
        
        [self setRegion:MKCoordinateRegionMake(originalRegion.center, originalRegion.span)
               animated:NO];
    }
}

- (void)mapDoubleTapped:(UITapGestureRecognizer *)doubleTapRecognizer
{
    double zoomScale = 0.5;
    MKCoordinateSpan span = MKCoordinateSpanMake(self.region.span.latitudeDelta * zoomScale,
                                                 self.region.span.longitudeDelta * zoomScale);
    
    //NOTE: you can turn on animations, but for some reason it goes very slow and there's no way to change the speed
    [self setRegion:MKCoordinateRegionMake(self.region.center, span) animated:NO];
    [self doneZooming];
}

- (void)mapTwoFingerTapped:(UITapGestureRecognizer *)doubleFingerTapRecognizer
{
    double zoomScale = 2;
    MKCoordinateSpan span = MKCoordinateSpanMake(self.region.span.latitudeDelta * zoomScale,
                                                 self.region.span.longitudeDelta * zoomScale);
    
    if([self spanIsOutOfBounds:span])
        return;
    
    //NOTE: you can turn on animations, but for some reason it goes very slow and there's no way to change the speed
    [self setRegion:MKCoordinateRegionMake(self.region.center, span) animated:NO];
    [self doneZooming];
}

- (void)doneZooming
{
    if(self.doneZoomingBlock) {
        self.doneZoomingBlock();
    }
}

- (void)donePinching
{
    if(self.donePinchingBlock) {
        self.donePinchingBlock();
    }
}

- (BOOL)spanIsOutOfBounds:(MKCoordinateSpan)span
{
    //spans set too large will crash the app, so we have to limit it
    //spans with longitudeDelta of ~ more than 140 will crash the app
    static double maxSpan = 140;
    
    if(span.longitudeDelta > maxSpan) {
        return YES;
    } else {
        return NO;
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if((gestureRecognizer == self.tapZoomOutRecognizer && otherGestureRecognizer == self.pinchRecognizer) ||
       (gestureRecognizer == self.pinchRecognizer && otherGestureRecognizer == self.tapZoomOutRecognizer))
    {
        //this makes sure that at the end of a pinch to zoom the two finger tap gesture isn't recognized
        return NO;
    }
    return YES;
}

#pragma mark Public

- (void)enableLockingZoom
{
    if(![self hasSetupGestureRecognizers]) {
        [self setupGestureRecognizers];
    }
    
    self.zoomEnabled = NO;
    
    [self addGestureRecognizer:self.pinchRecognizer];
    [self addGestureRecognizer:self.tapZoomInRecognizer];
    [self addGestureRecognizer:self.tapZoomOutRecognizer];
}

- (void)disableLockingZoom
{
    self.zoomEnabled = YES;
    
    [self removeGestureRecognizer:self.pinchRecognizer];
    [self removeGestureRecognizer:self.tapZoomInRecognizer];
    [self removeGestureRecognizer:self.tapZoomOutRecognizer];
}

#pragma mark Associated objects to make properties within MapViewCategory
- (void)setPinchRecognizer:(UIPinchGestureRecognizer *)pinchRecognizer
{
    objc_setAssociatedObject(self, &pinchKey, pinchRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIPinchGestureRecognizer *)pinchRecognizer
{
    return objc_getAssociatedObject(self, &pinchKey);
}

- (void)setTapZoomOutRecognizer:(UITapGestureRecognizer *)tapZoomOutRecognizer
{
    objc_setAssociatedObject(self, &tapZoomOutKey, tapZoomOutRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UITapGestureRecognizer *)tapZoomOutRecognizer
{
    return objc_getAssociatedObject(self, &tapZoomOutKey);
}

- (void)setTapZoomInRecognizer:(UITapGestureRecognizer *)tapZoomInRecognizer
{
    objc_setAssociatedObject(self, &tapZoomInKey, tapZoomInRecognizer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UITapGestureRecognizer *)tapZoomInRecognizer
{
    return objc_getAssociatedObject(self, &tapZoomInKey);
}

- (void)setDonePinchingBlock:(void(^)())donePinchingBlock
{
    objc_setAssociatedObject(self, &donePinchingBlockKeyDH, donePinchingBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void(^)())donePinchingBlock
{
    return objc_getAssociatedObject(self, &donePinchingBlockKeyDH);
}

- (void)setDoneZoomingBlock:(void(^)())doneZoomingBlock
{
    objc_setAssociatedObject(self, &doneZoomingBlockKeyDH, doneZoomingBlock, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (void(^)())doneZoomingBlock
{
    return objc_getAssociatedObject(self, &doneZoomingBlockKeyDH);
}

@end
