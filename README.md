# MapHacks for iOS
Some convenience categories for Apple &amp; Google map sdks

## Locking zoom categories with more granular gesture response blocks.

### Apple's MKMapKit

    self.mapView = [[MKMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    
    [self.mapView enableLockingZoom];
    
### Google Maps GSMapView

    self.mapView = [[GMSMapView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.mapView];
    self.mapView.delegate = self;
    
    [self.mapView enableLockingZoom];
    

