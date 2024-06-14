//
//  OAXmlStreamReader.m
//  OsmAnd Maps
//
//  Created by Alexey K on 13.06.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAXmlStreamReader.h"
#include <QFile>
#include <QString>
#include <QIODevice>
#include <QXmlStreamReader>

NSString * const OAXmlStreamReaderErrorDomain = @"OAXmlStreamReaderError";

@implementation OAXmlStreamReader
{
    QXmlStreamReader _reader;
    NSString *_filePath;
    QByteArray _data;
}

- (BOOL)hasError __attribute__((swift_name("hasError()")))
{
    return _reader.hasError();
}

- (int32_t)getError __attribute__((swift_name("getError()")))
{
    QXmlStreamReader::Error error = _reader.error();
    switch (error)
    {
        case QXmlStreamReader::NoError:
            return 0;//OASXmlPullParserAPICompanion.companion.NO_ERROR;
        case QXmlStreamReader::UnexpectedElementError:
            return 1;//OASXmlPullParserAPICompanion.companion.UNEXPECTED_ELEMENT_ERROR;
        case QXmlStreamReader::CustomError:
            return 2;//OASXmlPullParserAPICompanion.companion.CUSTOM_ERROR;
        case QXmlStreamReader::NotWellFormedError:
            return 3;//OASXmlPullParserAPICompanion.companion.NOT_WELL_FORMED_ERROR;
        case QXmlStreamReader::PrematureEndOfDocumentError:
            return 4;//OASXmlPullParserAPICompanion.companion.PREMATURE_END_OF_DOCUMENT_ERROR;
        default:
            return 0;//OASXmlPullParserAPICompanion.companion.NO_ERROR;
    }
}

- (NSString *)getErrorString __attribute__((swift_name("getErrorString()")))
{
    return _reader.errorString().toNSString();
}

- (BOOL)setFeatureName:(NSString *)name state:(BOOL)state error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setFeature(name:state:)")))
{
    return NO; // Not implemented
}

- (BOOL)getFeatureName:(NSString *)name __attribute__((swift_name("getFeature(name:)")))
{
    return NO; // Not implemented
}

- (BOOL)setPropertyName:(NSString *)name value:(id _Nullable)value error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setProperty(name:value:)")))
{
    return NO; // Not implemented
}

- (id _Nullable)getPropertyName:(NSString *)name __attribute__((swift_name("getProperty(name:)")))
{
    return nil; // Not implemented
}

- (BOOL)setInputFilePath:(NSString *)filePath inputEncoding:(NSString * _Nullable)inputEncoding error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setInput(filePath:inputEncoding:)")))
{
    QFile file(QString::fromNSString(filePath));
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
        return NO;

    _reader.clear();
    _filePath = filePath;
    _reader.setDevice(&file);
    return YES;
}

- (BOOL)setInputData:(NSData *)data inputEncoding:(NSString * _Nullable)inputEncoding error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setInput(data:inputEncoding:)")))
{
    _reader.clear();
    _data.clear();
    _data.append(QByteArray::fromNSData(data));
    _reader.addData(_data);
    return YES;
}

- (BOOL)closeAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("close_()")))
{
    _reader.clear();
    _data.clear();
    return YES;
}

- (NSString * _Nullable)getInputEncoding __attribute__((swift_name("getInputEncoding()")))
{
    return _reader.documentEncoding().string()->toNSString();
}

- (BOOL)defineEntityReplacementTextEntityName:(NSString *)entityName replacementText:(NSString *)replacementText error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("defineEntityReplacementText(entityName:replacementText:)")))
{
    return NO; // Not implemented
}

- (int32_t)getNamespaceCountDepth:(int32_t)depth error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getNamespaceCount(depth:)"))) __attribute__((swift_error(nonnull_error)))
{
    return -1; // Not implemented
}

- (NSString * _Nullable)getNamespacePrefixPos:(int32_t)pos error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getNamespacePrefix(pos:)"))) __attribute__((swift_error(nonnull_error)))
{
    return nil; // Not implemented
}

- (NSString * _Nullable)getNamespaceUriPos:(int32_t)pos error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getNamespaceUri(pos:)"))) __attribute__((swift_error(nonnull_error)))
{
    return nil; // Not implemented
}

- (NSString * _Nullable)getNamespacePrefix:(NSString * _Nullable)prefix __attribute__((swift_name("getNamespace(prefix:)")))
{
    return nil; // Not implemented
}

- (int32_t)getDepth __attribute__((swift_name("getDepth()")))
{
    return -1; // Not implemented
}

- (NSString * _Nullable)getPositionDescription __attribute__((swift_name("getPositionDescription()")))
{
    return nil; // Not implemented
}

- (int32_t)getLineNumber __attribute__((swift_name("getLineNumber()")))
{
    return (int32_t)_reader.lineNumber();
}

- (int32_t)getColumnNumber __attribute__((swift_name("getColumnNumber()")))
{
    return (int32_t)_reader.columnNumber();
}

- (BOOL)isWhitespaceAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("isWhitespace()"))) __attribute__((swift_error(nonnull_error)))
{
    return _reader.isWhitespace();
}

- (NSString * _Nullable)getText __attribute__((swift_name("getText()")))
{
    return _reader.text().string()->toNSString();
}

- (OASKotlinCharArray * _Nullable)getTextCharactersHolderForStartAndLength:(OASKotlinIntArray *)holderForStartAndLength __attribute__((swift_name("getTextCharacters(holderForStartAndLength:)")))
{
    return nil; // Not implemented
}

- (NSString * _Nullable)getNamespace __attribute__((swift_name("getNamespace()")))
{
    return _reader.namespaceUri().string()->toNSString();
}

- (NSString * _Nullable)getName __attribute__((swift_name("getName()")))
{
    return _reader.name().string()->toNSString();
}

- (NSString * _Nullable)getPrefix __attribute__((swift_name("getPrefix()")))
{
    return _reader.prefix().string()->toNSString();
}

- (BOOL)isEmptyElementTagAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("isEmptyElementTag()"))) __attribute__((swift_error(nonnull_error)))
{
    return NO; // Not implemented
}

- (int32_t)getAttributeCount __attribute__((swift_name("getAttributeCount()")))
{
    return _reader.attributes().count();
}

- (NSString * _Nullable)getAttributeNamespaceIndex:(int32_t)index __attribute__((swift_name("getAttributeNamespace(index:)")))
{
    return _reader.attributes().at(index).namespaceUri().string()->toNSString();
}

- (NSString * _Nullable)getAttributeNameIndex:(int32_t)index __attribute__((swift_name("getAttributeName(index:)")))
{
    return _reader.attributes().at(index).name().string()->toNSString();
}

- (NSString * _Nullable)getAttributePrefixIndex:(int32_t)index __attribute__((swift_name("getAttributePrefix(index:)")))
{
    return _reader.attributes().at(index).prefix().string()->toNSString();
}

- (NSString * _Nullable)getAttributeTypeIndex:(int32_t)index __attribute__((swift_name("getAttributeType(index:)")))
{
    return nil; // Not implemented
}

- (BOOL)isAttributeDefaultIndex:(int32_t)index __attribute__((swift_name("isAttributeDefault(index:)")))
{
    return NO; // Not implemented
}

- (NSString * _Nullable)getAttributeValueIndex:(int32_t)index __attribute__((swift_name("getAttributeValue(index:)")))
{
    return _reader.attributes().at(index).value().string()->toNSString();
}

- (NSString * _Nullable)getAttributeValueNamespace:(NSString * _Nullable)namespace_ name:(NSString * _Nullable)name __attribute__((swift_name("getAttributeValue(namespace:name:)")))
{
    return _reader.attributes().value(QString::fromNSString(namespace_), QString::fromNSString(name)).string()->toNSString();
}

- (int32_t)getEventTypeAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getEventType()"))) __attribute__((swift_error(nonnull_error)))
{
    QXmlStreamReader::TokenType type = _reader.tokenType();
    switch (type)
    {
        case QXmlStreamReader::StartDocument:
            return 0;//OASXmlPullParserCompanion.companion.START_DOCUMENT;
        case QXmlStreamReader::EndDocument:
            return 1;//OASXmlPullParserCompanion.companion.END_DOCUMENT;
        case QXmlStreamReader::StartElement:
            return 2;//OASXmlPullParserCompanion.companion.START_TAG;
        case QXmlStreamReader::EndElement:
            return 3;//OASXmlPullParserCompanion.companion.END_TAG;
        case QXmlStreamReader::Characters:
            return 4;//OASXmlPullParserCompanion.companion.TEXT;
        case QXmlStreamReader::Comment:
            return 9;//OASXmlPullParserCompanion.companion.COMMENT;
        case QXmlStreamReader::ProcessingInstruction:
            return 8;//OASXmlPullParserCompanion.companion.PROCESSING_INSTRUCTION;
        case QXmlStreamReader::EntityReference:
            return 6;//OASXmlPullParserCompanion.companion.ENTITY_REF;
        case QXmlStreamReader::DTD:
            return 10;//OASXmlPullParserCompanion.companion.DOCDECL;

        default:
            return -1; // NoToken and Invalid not parsed
    }
}

- (int32_t)nextAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("next()"))) __attribute__((swift_error(nonnull_error)))
{
    return _reader.readNext();
}

- (int32_t)nextTokenAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("nextToken()"))) __attribute__((swift_error(nonnull_error)))
{
    return -1; // Not implemented
}

- (BOOL)requireType:(int32_t)type namespace:(NSString * _Nullable)namespace_ name:(NSString * _Nullable)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("require(type:namespace:name:)")))
{
    return NO; // Not implemented
}

- (NSString * _Nullable)nextTextAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("nextText()")))
{
    return nil; // Not implemented
}

- (int32_t)nextTagAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("nextTag()"))) __attribute__((swift_error(nonnull_error)))
{
    return -1; // Not implemented
}

@end
