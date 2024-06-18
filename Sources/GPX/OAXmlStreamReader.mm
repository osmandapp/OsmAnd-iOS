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
            return OASXmlPullParserAPICompanion.companion.NO_ERROR;
        case QXmlStreamReader::UnexpectedElementError:
            return OASXmlPullParserAPICompanion.companion.UNEXPECTED_ELEMENT_ERROR;
        case QXmlStreamReader::CustomError:
            return OASXmlPullParserAPICompanion.companion.CUSTOM_ERROR;
        case QXmlStreamReader::NotWellFormedError:
            return OASXmlPullParserAPICompanion.companion.NOT_WELL_FORMED_ERROR;
        case QXmlStreamReader::PrematureEndOfDocumentError:
            return OASXmlPullParserAPICompanion.companion.PREMATURE_END_OF_DOCUMENT_ERROR;
        default:
            return OASXmlPullParserAPICompanion.companion.NO_ERROR;
    }
}

- (NSString *)getErrorString __attribute__((swift_name("getErrorString()")))
{
    return _reader.errorString().toNSString();
}

- (BOOL)setFeatureName:(NSString *)name state:(BOOL)state error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setFeature(name:state:)")))
{
    return YES; // Not implemented
}

- (BOOL)getFeatureName:(NSString *)name __attribute__((swift_name("getFeature(name:)")))
{
    return YES; // Not implemented
}

- (BOOL)setPropertyName:(NSString *)name value:(id _Nullable)value error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setProperty(name:value:)")))
{
    return YES; // Not implemented
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
    _reader.setDevice(&file);
    return YES;
}

- (BOOL)setInputData:(NSData *)data inputEncoding:(NSString * _Nullable)inputEncoding error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("setInput(data:inputEncoding:)")))
{
    _reader.clear();
    _reader.addData((const char *)data.bytes);
    return YES;
}

- (BOOL)closeAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("close_()")))
{
    _reader.clear();
    return YES;
}

- (NSString * _Nullable)getInputEncoding __attribute__((swift_name("getInputEncoding()")))
{
    return _reader.documentEncoding().isNull() ? nil : _reader.documentEncoding().toString().toNSString();
}

- (BOOL)defineEntityReplacementTextEntityName:(NSString *)entityName replacementText:(NSString *)replacementText error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("defineEntityReplacementText(entityName:replacementText:)")))
{
    return YES; // Not implemented
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
    return _reader.text().isNull() ? nil : _reader.text().toString().toNSString();
}

- (OASKotlinCharArray * _Nullable)getTextCharactersHolderForStartAndLength:(OASKotlinIntArray *)holderForStartAndLength __attribute__((swift_name("getTextCharacters(holderForStartAndLength:)")))
{
    return nil; // Not implemented
}

- (NSString * _Nullable)getNamespace __attribute__((swift_name("getNamespace()")))
{
    return _reader.namespaceUri().isNull() ? nil : _reader.namespaceUri().toString().toNSString();
}

- (NSString * _Nullable)getName __attribute__((swift_name("getName()")))
{
    return _reader.name().isNull() ? nil : _reader.name().toString().toNSString();
}

- (NSString * _Nullable)getPrefix __attribute__((swift_name("getPrefix()")))
{
    return _reader.prefix().isNull() ? nil : _reader.prefix().toString().toNSString();
}

- (BOOL)isEmptyElementTagAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("isEmptyElementTag()"))) __attribute__((swift_error(nonnull_error)))
{
    return YES; // Not implemented
}

- (int32_t)getAttributeCount __attribute__((swift_name("getAttributeCount()")))
{
    return _reader.attributes().count();
}

- (NSString * _Nullable)getAttributeNamespaceIndex:(int32_t)index __attribute__((swift_name("getAttributeNamespace(index:)")))
{
    const auto& namespaceUri = _reader.attributes().at(index).namespaceUri();
    return namespaceUri.isNull() ? nil : namespaceUri.toString().toNSString();
}

- (NSString * _Nullable)getAttributeNameIndex:(int32_t)index __attribute__((swift_name("getAttributeName(index:)")))
{
    const auto& name = _reader.attributes().at(index).name();
    return name.isNull() ? nil : name.toString().toNSString();
}

- (NSString * _Nullable)getAttributePrefixIndex:(int32_t)index __attribute__((swift_name("getAttributePrefix(index:)")))
{
    const auto& prefix = _reader.attributes().at(index).prefix();
    return prefix.isNull() ? nil : prefix.toString().toNSString();
}

- (NSString * _Nullable)getAttributeTypeIndex:(int32_t)index __attribute__((swift_name("getAttributeType(index:)")))
{
    return nil; // Not implemented
}

- (BOOL)isAttributeDefaultIndex:(int32_t)index __attribute__((swift_name("isAttributeDefault(index:)")))
{
    return YES; // Not implemented
}

- (NSString * _Nullable)getAttributeValueIndex:(int32_t)index __attribute__((swift_name("getAttributeValue(index:)")))
{
    const auto& value = _reader.attributes().at(index).value();
    return value.isNull() ? nil : value.toString().toNSString();
}

- (NSString * _Nullable)getAttributeValueNamespace:(NSString * _Nullable)namespace_ name:(NSString * _Nullable)name __attribute__((swift_name("getAttributeValue(namespace:name:)")))
{
    const auto& value = _reader.attributes().value(QString::fromNSString(namespace_), QString::fromNSString(name));
    return value.isNull() ? nil : value.toString().toNSString();
}

- (int32_t)getEventTypeAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("getEventType()"))) __attribute__((swift_error(nonnull_error)))
{
    return [self convertTokenType: _reader.tokenType()];
}

- (int32_t)convertTokenType:(QXmlStreamReader::TokenType)type
{
    switch (type)
    {
        case QXmlStreamReader::StartDocument:
            return OASXmlPullParserCompanion.companion.START_DOCUMENT;
        case QXmlStreamReader::EndDocument:
            return OASXmlPullParserCompanion.companion.END_DOCUMENT;
        case QXmlStreamReader::StartElement:
            return OASXmlPullParserCompanion.companion.START_TAG;
        case QXmlStreamReader::EndElement:
            return OASXmlPullParserCompanion.companion.END_TAG;
        case QXmlStreamReader::Characters:
            return OASXmlPullParserCompanion.companion.TEXT;
        case QXmlStreamReader::Comment:
            return OASXmlPullParserCompanion.companion.COMMENT;
        case QXmlStreamReader::ProcessingInstruction:
            return OASXmlPullParserCompanion.companion.PROCESSING_INSTRUCTION;
        case QXmlStreamReader::EntityReference:
            return OASXmlPullParserCompanion.companion.ENTITY_REF;
        case QXmlStreamReader::DTD:
            return OASXmlPullParserCompanion.companion.DOCDECL;

        default:
            return -1; // NoToken and Invalid not parsed
    }
}

- (int32_t)nextAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("next()"))) __attribute__((swift_error(nonnull_error)))
{
    return [self convertTokenType:_reader.readNext()];
}

- (int32_t)nextTokenAndReturnError:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("nextToken()"))) __attribute__((swift_error(nonnull_error)))
{
    return -1; // Not implemented
}

- (BOOL)requireType:(int32_t)type namespace:(NSString * _Nullable)namespace_ name:(NSString * _Nullable)name error:(NSError * _Nullable * _Nullable)error __attribute__((swift_name("require(type:namespace:name:)")))
{
    return YES; // Not implemented
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
