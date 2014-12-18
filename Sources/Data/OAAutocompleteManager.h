//
//  OAAutocompleteManager.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 1/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HTAutocompleteTextField.h"
#import "OsmAndApp.h"

typedef enum {
    OAAutocompleteTypeCountry, // Default
} OAAutocompleteType;

@interface OAAutocompleteManager : NSObject <HTAutocompleteDataSource>

+ (OAAutocompleteManager *)sharedManager;

@property NSMutableArray *regionList;
@property NSMutableArray *bigCountryList;
@property OAWorldRegion* selectedRegion;

@end
