//
//  OAAutocompleteManager.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 1/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAutocompleteManager.h"
#import "OsmAndApp.h"
#import "OAWorldRegion.h"

static OAAutocompleteManager *sharedManager;

@implementation OAAutocompleteManager

+ (OAAutocompleteManager *)sharedManager
{
	static dispatch_once_t done;
	dispatch_once(&done, ^{
        sharedManager = [[OAAutocompleteManager alloc] init];
        sharedManager.regionList = [[NSMutableArray alloc] init];
        sharedManager.bigCountryList = [[NSMutableArray alloc] init];

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
            for(NSString* regName in region.allNames) {
                if (regName && [[regName lowercaseString] hasPrefix:stringToLookFor]) {
                    NSString *lcRegName = [regName lowercaseString];
                    self.selectedRegion = region;
                    return [regName stringByReplacingCharactersInRange:[lcRegName rangeOfString:stringToLookFor] withString:@""];
                }
            }
            if(region.superregion.downloadsIdPrefix && region.superregion.downloadsIdPrefix.length > 0) {
                for(NSString* regName in region.superregion.allNames) {
                    if (regName && [[regName lowercaseString] hasPrefix:stringToLookFor]) {
                        NSString *lcRegName = [regName lowercaseString];
                        self.selectedRegion = region;
                        NSString *subName = [regName stringByReplacingCharactersInRange:[lcRegName rangeOfString:stringToLookFor] withString:@""];
                        return  [NSString stringWithFormat:@"%@ %@", subName, region.name];
                    }
                }
            }
        }
    }
    self.selectedRegion = nil;
    
    return @"";
}


-(void)findRegionsInRegion:(OAWorldRegion*)region {

    [region.subregions enumerateObjectsUsingBlock:^(OAWorldRegion* subregion, NSUInteger idx, BOOL *stop) {
        if (subregion.subregions.count == 0) {
            [self.regionList addObject:subregion];
        } else {
            if(subregion.downloadsIdPrefix && subregion.downloadsIdPrefix.length > 0) {
                [self.bigCountryList addObject:subregion];
            }
            [self findRegionsInRegion:subregion];
        }
    }];
    
}

@end
