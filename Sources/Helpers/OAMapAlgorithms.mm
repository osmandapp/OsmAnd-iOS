//
//  OAMapAlgorithms.m
//  OsmAnd Maps
//
//  Created by nnngrach on 15.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMapAlgorithms.h"
#import "OAGPXDocumentPrimitives.h"
#import "OsmAndSharedWrapper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAMapAlgorithms : NSObject

+ (QList<int>) decodeIntHeightArrayGraph:(const QString &)str repeatBits:(int)repeatBits
{
    int maxRepeats = (1 << repeatBits) - 1;
    QList<int> res;
    std::string ch = str.toUtf8().constData();
    res.push_back(ch[0]);
    
    for (int i = 1; i < ch.size(); ++i)
    {
        char c = ch[i];
        
        for (int rept = c & maxRepeats; rept > 0; --rept)
        {
            res.push_back(0);
        }
        
        int num = c >> repeatBits;
        if (num % 2 == 0)
        {
            res.push_back(num >> 1);
        }
        else
        {
            res.push_back(-(num >> 1));
        }
    }
    
    return res;
}

+ (OASTrkSegment *) augmentTrkSegmentWithAltitudes:(OASTrkSegment *)sgm decodedSteps:(const QList<int> &)decodedSteps startEle:(double)startEle
{
    OASTrkSegment *segment = sgm;
    NSMutableArray<OASWptPt *> *points = [NSMutableArray arrayWithArray:sgm.points];
    
    int stepDist = decodedSteps[0];
    int stepHNextInd = 1;
    double prevHDistX = 0;
    points[0].ele = startEle;
    
    for (NSInteger i = 1; i < points.count; ++i)
    {
        OASWptPt *prev = points[i - 1];
        OASWptPt *cur = points[i];
        double origHDistX = prevHDistX;
        double len = [OAMapUtils getDistance:prev.position.latitude lon1:prev.position.longitude lat2:cur.position.latitude lon2:cur.position.longitude] / stepDist;
        double curHDistX = len + prevHDistX;
        
        double hInc;
        for (hInc = 0; curHDistX > stepHNextInd && stepHNextInd < decodedSteps.size(); ++stepHNextInd)
        {
            if (prevHDistX < stepHNextInd)
            {
                hInc += (stepHNextInd - prevHDistX) * decodedSteps[stepHNextInd];
                if (stepHNextInd - prevHDistX > 0.5)
                {
                    double fraction = (stepHNextInd - prevHDistX) / (curHDistX - origHDistX);
                    OASWptPt *newPt = [[OASWptPt alloc] init];
                    double lat = prev.position.latitude + fraction * (cur.position.latitude - prev.position.latitude);
                    double lon = prev.position.longitude + fraction * (cur.position.longitude - prev.position.longitude);
                    newPt.position = CLLocationCoordinate2DMake(lat, lon);
                    newPt.ele = prev.ele + hInc;
                    [points insertObject:newPt atIndex:i];
                    ++i;
                }
                
                prevHDistX = stepHNextInd;
            }
        }
        
        if (stepHNextInd < decodedSteps.size())
        {
            hInc += (curHDistX - prevHDistX) * decodedSteps[stepHNextInd];
        }

        cur.ele = prev.ele + hInc;
        prevHDistX = curHDistX;
        
        points[i - 1] = prev;
        points[i] = cur;
    }
    
    sgm.points = points;
    return sgm;
}

@end
