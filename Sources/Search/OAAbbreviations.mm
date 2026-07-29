//
//  OAAbbreviations.mm
//  OsmAnd Maps
//
//  Created by plotva on 30.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OAAbbreviations.h"

#include <OsmAndCore/Search/Abbreviations.h>

static QSet<QString> OAAbbreviationsToQSet(NSSet<NSString *> *values)
{
    QSet<QString> result;
    for (NSString *value in values)
    {
        result.insert(QString::fromNSString(value));
    }
    return result;
}

static NSDictionary<NSString *, NSString *> *OAAbbreviationsToNSDictionary(
    const QHash<QString, QString>& values)
{
    NSMutableDictionary<NSString *, NSString *> *result =
        [NSMutableDictionary dictionaryWithCapacity:values.size()];
    for (auto it = values.constBegin(); it != values.constEnd(); ++it)
    {
        result[it.key().toNSString()] = it.value().toNSString();
    }
    return [result copy];
}

@implementation OAAbbreviations

+ (BOOL) likelyPartOfRef:(NSString *)word wordSplit:(NSSet<NSString *> *)wordSplit
{
    const QSet<QString> qWordSplit = OAAbbreviationsToQSet(wordSplit);
    return OsmAnd::Abbreviations::likelyPartOfRef(QString::fromNSString(word), qWordSplit);
}

+ (BOOL) likelyPartOfBuilding:(NSString *)word wordSplit:(NSSet<NSString *> *)wordSplit
{
    const QSet<QString> qWordSplit = OAAbbreviationsToQSet(wordSplit);
    return OsmAnd::Abbreviations::likelyPartOfBuilding(
        QString::fromNSString(word),
        wordSplit == nil ? nullptr : &qWordSplit);
}

+ (NSDictionary<NSString *, NSString *> *) getSearchAbbreviations
{
    return OAAbbreviationsToNSDictionary(OsmAnd::Abbreviations::getSearchabbreviations());
}

+ (BOOL) isCommonSkipOtherCnt:(NSString *)lowerCase
{
    return OsmAnd::Abbreviations::isCommonSkipOtherCnt(QString::fromNSString(lowerCase));
}

+ (NSString *) replace:(NSString *)word
{
    return OsmAnd::Abbreviations::replace(QString::fromNSString(word)).toNSString();
}

+ (NSString *) replaceAll:(NSString *)phrase
{
    return OsmAnd::Abbreviations::replaceAll(QString::fromNSString(phrase)).toNSString();
}

+ (NSDictionary<NSString *, NSString *> *) getAbbreviations
{
    return OAAbbreviationsToNSDictionary(OsmAnd::Abbreviations::getAbbreviations());
}

+ (BOOL) isConjunction:(NSString *)lowerCase
{
    return OsmAnd::Abbreviations::isConjunction(QString::fromNSString(lowerCase));
}

@end
