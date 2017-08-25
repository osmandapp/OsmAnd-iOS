//
//  OAMapActions.m
//  OsmAnd
//
//  Created by Alexey Kulish on 22/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapActions.h"
#import "OAPointDescription.h"
#import "OsmAndApp.h"
#import "OASelectedGPXHelper.h"
#import "OAGPXDatabase.h"

@implementation OAMapActions

- (void) enterRoutePlanningMode:(CLLocation *)from fromName:(OAPointDescription *)fromName
{
    BOOL useIntermediatePointsByDefault = true;
    
    OASelectedGPXHelper *_helper = [OASelectedGPXHelper instance];
    OAGPXDatabase *_dbHelper = [OAGPXDatabase sharedDb];
    NSMutableArray<OAGPX *> *gpxFiles = [NSMutableArray array];
    for (auto it = _helper.activeGpx.begin(); it != _helper.activeGpx.end(); ++it)
    {
        OAGPX *gpx = [_dbHelper getGPXItem:it.key().toNSString()];
        if (gpx)
        {
            auto doc = it.value();
            if (doc->hasRtePt() || doc->hasTrkPt())
            {
                [gpxFiles addObject:gpx];
            }
        }
    }
    
    /*
    if (gpxFiles.count > 0)
    {
        AlertDialog.Builder bld = new AlertDialog.Builder(mapActivity);
        if (gpxFiles.size() == 1) {
            bld.setMessage(R.string.use_displayed_track_for_navigation);
            bld.setPositiveButton(R.string.shared_string_yes, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialog, int which) {
                    enterRoutePlanningModeGivenGpx(gpxFiles.get(0), from, fromName, useIntermediatePointsByDefault, true);
                }
            });
        } else {
            bld.setTitle(R.string.navigation_over_track);
            ArrayAdapter<GPXFile> adapter = new ArrayAdapter<GPXFile>(mapActivity, R.layout.drawer_list_item, gpxFiles) {
                @Override
                public View getView(int position, View convertView, ViewGroup parent) {
                    if (convertView == null) {
                        convertView = mapActivity.getLayoutInflater().inflate(R.layout.drawer_list_item, null);
                    }
                    String path = getItem(position).path;
                    String name = path.substring(path.lastIndexOf("/") + 1, path.length());
                    ((TextView) convertView.findViewById(R.id.title)).setText(name);
                    convertView.findViewById(R.id.icon).setVisibility(View.GONE);
                    convertView.findViewById(R.id.toggle_item).setVisibility(View.GONE);
                    return convertView;
                }
            };
            bld.setAdapter(adapter, new DialogInterface.OnClickListener() {
                @Override
                public void onClick(DialogInterface dialogInterface, int i) {
                    enterRoutePlanningModeGivenGpx(gpxFiles.get(i), from, fromName, useIntermediatePointsByDefault, true);
                }
            });
        }
        
        bld.setNegativeButton(R.string.shared_string_no, new DialogInterface.OnClickListener() {
            @Override
            public void onClick(DialogInterface dialog, int which) {
                enterRoutePlanningModeGivenGpx(null, from, fromName, useIntermediatePointsByDefault, true);
            }
        });
        bld.show();
    } else {
        enterRoutePlanningModeGivenGpx(null, from, fromName, useIntermediatePointsByDefault, true);
    }
     */
}

@end
