//
//  OAAutocompleteManager.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 1/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAutocompleteManager.h"
#import "OsmAndApp.h"

static OAAutocompleteManager *sharedManager;

@implementation OAAutocompleteManager

+ (OAAutocompleteManager *)sharedManager
{
	static dispatch_once_t done;
	dispatch_once(&done, ^{
        sharedManager = [[OAAutocompleteManager alloc] init];
        sharedManager.regionList = [[NSMutableArray alloc] init];

        OsmAndAppInstance app = [OsmAndApp instance];
        [sharedManager findRegionsInRegion:app.worldRegion];
    });
	return sharedManager;
}

#pragma mark - HTAutocompleteTextFieldDelegate

- (NSString *)textField:(HTAutocompleteTextField *)textField
    completionForPrefix:(NSString *)prefix
             ignoreCase:(BOOL)ignoreCase
{
    
    if (textField.autocompleteType == OAAutocompleteTypeCountry)
    {
        NSString *stringToLookFor;
		NSArray *componentsString = [prefix componentsSeparatedByString:@","];
        NSString *prefixLastComponent = [componentsString.lastObject stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (ignoreCase)
            stringToLookFor = [prefixLastComponent lowercaseString];
        else
            stringToLookFor = prefixLastComponent;
        
        
        for (OAWorldRegion* region in self.regionList) {
            NSString *stringToCompare;
            NSString *localStringToCompare;
            if (ignoreCase) {
                stringToCompare = [region.name lowercaseString];
                localStringToCompare = [region.localizedName lowercaseString];
            }
            else {
                stringToCompare = region.name;
                localStringToCompare = region.localizedName;
            }
            
            if (region.name && [[region.name lowercaseString] hasPrefix:stringToLookFor])
                return [region.name stringByReplacingCharactersInRange:[stringToCompare rangeOfString:stringToLookFor] withString:@""];
            if (region.localizedName && [[region.localizedName lowercaseString] hasPrefix:stringToLookFor])
                return [region.localizedName stringByReplacingCharactersInRange:[localStringToCompare rangeOfString:stringToLookFor] withString:@""];
        }
    }
    
    return @"";
}


-(void)findRegionsInRegion:(OAWorldRegion*)region {

    [region.subregions enumerateObjectsUsingBlock:^(OAWorldRegion* subregion, NSUInteger idx, BOOL *stop) {
        if (subregion.subregions.count == 0) {
            [self.regionList addObject:subregion];
        } else {
            [self findRegionsInRegion:subregion];
        }
    }];
    
}

@end
