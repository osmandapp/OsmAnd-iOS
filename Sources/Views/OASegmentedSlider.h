//
//  OASegmentedSlider.h
//  OsmAnd
//
//  Created by Skalii on 07.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASlider.h"

@interface OASegmentedSlider : OASlider

@property (nonatomic) NSInteger numberOfMarks;
@property (nonatomic) NSInteger selectedMark;

- (void)setCurrentMark:(NSInteger)currentMark;

- (void)setNumberOfMarks:(NSInteger)numberOfMarks
  additionalMarksBetween:(NSInteger)additionalMarksBetween;

- (void)makeCustom:(UIColor *)customMinimumTrackTintColor
    customMaximumTrackTintColor:(UIColor *)customMaximumTrackTintColor
         customCurrentMarkColor:(UIColor *)customCurrentMarkColor;

@end
