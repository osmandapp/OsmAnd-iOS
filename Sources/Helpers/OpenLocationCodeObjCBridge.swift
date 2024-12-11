//===--- OpenLocationCode.swift - Open Location Code encoding/decoding-----===//
//
//  Copyright 2017 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//===----------------------------------------------------------------------===//
//
//  Convert between decimal degree coordinates and Open Location Codes. Shorten
//  and recover Open Location Codes for a given reference location.
//
//  Exposes the Swift objects in OpenLocationCode.swift as NSObject visible in
//  Objective-C. The reason that OpenLocationCode and OpenLocationCodeArea don't
//  descend from NSObject directly is that such classes can't be used in Swift
//  for Linux and this time. It also allows for more "pure" swift paradigms to
//  be employed for those objects, such as the declaring OpenLocationCodeArea
//  as a struct, and more customization for the Objective-C representation
//  such as with default parameters.
//
//  Authored by William Denniss.
//
//===----------------------------------------------------------------------===//

import Foundation

#if !os(Linux)

/// Convert between decimal degree coordinates and plus codes. Shorten and
/// recover plus codes for a given reference location.
///
/// Open Location Codes are short, 10-11 character codes that can be used
/// instead of street addresses. The codes can be generated and decoded offline,
/// and use a reduced character set that minimises the chance of codes including
/// words.
///
/// Codes are able to be shortened relative to a nearby location. This means
/// that in many cases, only four to seven characters of the code are needed.
/// To recover the original code, the same location is not required, as long as
/// a nearby location is provided.
///
/// Codes represent rectangular areas rather than points, and the longer the
/// code, the smaller the area. A 10 character code represents a 13.5x13.5
/// meter area (at the equator. An 11 character code represents approximately
/// a 2.8x3.5 meter area.
///
/// Two encoding algorithms are used. The first 10 characters are pairs of
/// characters, one for latitude and one for latitude, using base 20. Each pair
/// reduces the area of the code by a factor of 400. Only even code lengths are
/// sensible, since an odd-numbered length would have sides in a ratio of 20:1.
///
/// At position 11, the algorithm changes so that each character selects one
/// position from a 4x5 grid. This allows single-character refinements.
///
/// # Swift Example
/// ```
/// import OpenLocationCode
///
/// // ...
///
/// // Encode a location with default code length.
/// if let code = OpenLocationCode.encode(latitude: 37.421908,
///                                       longitude: -122.084681) {
///   print("Open Location Code: \(code)")
/// }
///
/// // Encode a location with specific code length.
/// if let code10Digit = OpenLocationCode.encode(latitude: 37.421908,
///                                              longitude: -122.084681,
///                                              codeLength: 10) {
///   print("Open Location Code: \(code10Digit)")
/// }
///
/// // Decode a full code:
/// if let coord = OpenLocationCode.decode("849VCWC8+Q48") {
///   print("Center is \(coord.latitudeCenter), \(coord.longitudeCenter)")
/// }
///
/// // Attempt to trim the first characters from a code:
/// if let shortCode = OpenLocationCode.shorten(code: "849VCWC8+Q48",
///                                             latitude: 37.4,
///                                             longitude: -122.0) {
///   print("Short code: \(shortCode)")
/// }
///
/// // Recover the full code from a short code:
/// if let fullCode = OpenLocationCode.recoverNearest(shortcode: "CWC8+Q48",
///                                                   referenceLatitude: 37.4,
///                                                   referenceLongitude: -122.0) {
///   print("Recovered full code: \(fullCode)")
/// }
/// ```
/// # Objective-C Examples
/// ```
/// @import OpenLocationCode;
///
/// // ...
///
/// // Encode a location with default code length.
/// NSString *code = [OLCConverter encodeLatitude:37.421908
///                                     longitude:-122.084681];
/// OALog(@"Open Location Code: %@", code);
///
/// // Encode a location with specific code length.
/// NSString *code10Digit = [OLCConverter encodeLatitude:37.421908
///                                            longitude:-122.084681
///                                           codeLength:10];
/// OALog(@"Open Location Code: %@", code10Digit);
///
/// // Decode a full code:
/// OLCArea *coord = [OLCConverter decode:@"849VCWC8+Q48"];
/// OALog(@"Center is %.6f, %.6f", coord.latitudeCenter, coord.longitudeCenter);
/// 
/// // Attempt to trim the first characters from a code:
/// NSString *shortCode = [OLCConverter shortenCode:@"849VCWC8+Q48"
///                                        latitude:37.4
///                                       longitude:-122.0];
/// OALog(@"Short Code: %@", shortCode);
///
/// // Recover the full code from a short code:
/// NSString *recoveredCode = [OLCConverter recoverNearestWithShortcode:@"CWC8+Q48"
///                                                   referenceLatitude:37.4
///                                                  referenceLongitude:-122.1];
/// OALog(@"Recovered Full Code: %@", recoveredCode);
/// ```
///
@objc public class OLCConverter: NSObject {
  /// Determines if a code is valid.
  /// To be valid, all characters must be from the Open Location Code character
  /// set with at most one separator. The separator can be in any even-numbered
  /// position up to the eighth digit.
  ///
  /// - Parameter code: The Open Location Code to test.
  /// - Returns: true if the code is a valid Open Location Code.
  @objc(isValidCode:)
  public static func isValid(code: String) -> Bool {
    return OpenLocationCode.isValid(code: code)
  }

  /// Determines if a code is a valid short code.
  /// A short Open Location Code is a sequence created by removing four or more
  /// digits from an Open Location Code. It must include a separator
  /// character.
  ///
  /// - Parameter code: The Open Location Code to test.
  /// - Returns: true if the code is a short Open Location Code.
  @objc(isShortCode:)
  public static func isShort(code: String) -> Bool {
    return OpenLocationCode.isShort(code: code)

  }

  // Determines if a code is a valid full Open Location Code.
  // Not all possible combinations of Open Location Code characters decode to
  // valid latitude and longitude values. This checks that a code is valid
  // and also that the latitude and longitude values are legal. If the prefix
  // character is present, it must be the first character. If the separator
  // character is present, it must be after four characters.
  ///
  /// - Parameter code: The Open Location Code to test.
  /// - Returns: true if the code is a full Open Location Code.
  @objc(isFullCode:)
  public static func isFull(code: String) -> Bool {
    return OpenLocationCode.isFull(code: code)

  }
  /// Encode a location using the grid refinement method into an OLC string.
  /// The grid refinement method divides the area into a grid of 4x5, and uses a
  /// single character to refine the area. This allows default accuracy OLC
  /// codes to be refined with just a single character.
  ///
  /// - Parameter latitude: A latitude in signed decimal degrees.
  /// - Parameter longitude: A longitude in signed decimal degrees.
  /// - Parameter codeLength: The number of characters required.
  /// - Returns: Open Location Code representing the given grid.
  @objc(encodeGridForLatitude:longitude:codeLength:)
  public static func encodeGrid(latitude: Double,
                                longitude: Double,
                                codeLength: Int) -> String {
    return OpenLocationCode.encodeGrid(latitude:latitude,
                                       longitude:longitude,
                                       codeLength:codeLength)
  }

  /// Encode a location into an Open Location Code.
  /// Produces a code of the specified length, or the default length if no
  /// length is provided.
  /// The length determines the accuracy of the code. The default length is
  /// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  /// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  /// 11 or 12 are probably the limit of useful codes.
  ///
  /// - Parameter latitude: A latitude in signed decimal degrees. Will be
  ///   clipped to the range -90 to 90.
  /// - Parameter longitude: A longitude in signed decimal degrees. Will be
  ///   normalised to the range -180 to 180.
  /// - Parameter codeLength: The number of significant digits in the output
  ///   code, not including any separator characters. Possible values are;
  ///   `2`, `4`, `6`, `8`, `10`, `11`, `12`, `13` and above. Lower values
  ///   indicate a larger area, higher values a more precise area.
  ///   You can also shorten a code after encoding for codes used with a
  ///   reference point (e.g. your current location, a city, etc).
  ///
  /// - Returns: Open Location Code for the given coordinate.
  @objc(encodeLatitude:longitude:codeLength:)
  public static func encode(latitude: Double,
                            longitude: Double,
                            codeLength: Int) -> String? {
    return OpenLocationCode.encode(latitude:latitude, longitude:longitude,
                                   codeLength:codeLength)

  }

  /// Encode a location into an Open Location Code.
  /// Produces a code of the specified length, or the default length if no
  /// length is provided.
  /// The length determines the accuracy of the code. The default length is
  /// 10 characters, returning a code of approximately 13.5x13.5 meters. Longer
  /// codes represent smaller areas, but lengths > 14 are sub-centimetre and so
  /// 11 or 12 are probably the limit of useful codes.
  ///
  /// - Parameter latitude: A latitude in signed decimal degrees. Will be
  ///   clipped to the range -90 to 90.
  /// - Parameter longitude: A longitude in signed decimal degrees. Will be
  ///   normalised to the range -180 to 180.
  ///
  /// - Returns: Open Location Code for the given coordinate.
  @objc(encodeLatitude:longitude:)
  public static func encode(latitude: Double,
                            longitude: Double) -> String? {
    return OpenLocationCode.encode(latitude:latitude, longitude:longitude)

  }

  /// Decodes an Open Location Code into the location coordinates.
  /// Returns a OpenLocationCodeArea object that includes the coordinates of the
  /// bounding box - the lower left, center and upper right.
  ///
  /// - Parameter code: The Open Location Code to decode.
  /// - Returns: A CodeArea object that provides the latitude and longitude of
  ///   two of the corners of the area, the center, and the length of the
  ///   original code.
  @objc public static func decode(_ code: String) -> OLCArea? {
    guard let area = OpenLocationCode.decode(code) else {
      return nil
    }
    return OLCArea.init(area)
  }

  /// Recover the nearest matching code to a specified location.
  /// Given a short Open Location Code of between four and seven characters,
  /// this recovers the nearest matching full code to the specified location.
  /// The number of characters that will be prepended to the short code, depends
  /// on the length of the short code and whether it starts with the separator.
  /// If it starts with the separator, four characters will be prepended. If it
  /// does not, the characters that will be prepended to the short code, where S
  /// is the supplied short code and R are the computed characters, are as
  /// follows:
  /// ```
  /// SSSS  -> RRRR.RRSSSS
  /// SSSSS   -> RRRR.RRSSSSS
  /// SSSSSS  -> RRRR.SSSSSS
  /// SSSSSSS -> RRRR.SSSSSSS
  /// ```
  ///
  /// Note that short codes with an odd number of characters will have their
  /// last character decoded using the grid refinement algorithm.
  ///
  /// - Parameter shortcode: A valid short OLC character sequence.
  /// - Parameter referenceLatitude: The latitude (in signed decimal degrees) to
  ///   use to find the nearest matching full code.
  /// - Parameter referenceLongitude: The longitude (in signed decimal degrees)
  ///   to use to find the nearest matching full code.
  /// - Returns: The nearest full Open Location Code to the reference location
  ///   that matches the short code. If the passed code was not a valid short
  ///   code, but was a valid full code, it is returned unchanged.
  @objc public static func recoverNearest(shortcode: String,
                                    referenceLatitude: Double,
                                    referenceLongitude: Double) -> String? {
    return OpenLocationCode.recoverNearest(shortcode:shortcode,
        referenceLatitude:referenceLatitude,
        referenceLongitude:referenceLongitude)
  }

  /// Remove characters from the start of an OLC code.
  /// This uses a reference location to determine how many initial characters
  /// can be removed from the OLC code. The number of characters that can be
  /// removed depends on the distance between the code center and the reference
  /// location.
  /// The minimum number of characters that will be removed is four. If more
  /// than four characters can be removed, the additional characters will be
  /// replaced with the padding character. At most eight characters will be
  /// removed. The reference location must be within 50% of the maximum range.
  /// This ensures that the shortened code will be able to be recovered using
  /// slightly different locations.
  ///
  /// - Parameter code: A full, valid code to shorten.
  /// - Parameter latitude: A latitude, in signed decimal degrees, to use as the
  ///   reference point.
  /// - Parameter longitude: A longitude, in signed decimal degrees, to use as
  ///   the reference point.
  /// - Parameter maximumTruncation: The maximum number of characters to remove.
  /// - Returns: Either the original code, if the reference location was not
  ///   close enough, or the original.
  @objc(shortenCode:latitude:longitude:maximumTruncation:)
  public static func shorten(code: String,
                             latitude: Double,
                             longitude: Double,
                             maximumTruncation: Int) -> String? {
      return OpenLocationCode.shorten(code:code,
                                      latitude:latitude,
                                      longitude:longitude,
                                      maximumTruncation:maximumTruncation)
  }

  /// Remove characters from the start of an OLC code.
  /// This uses a reference location to determine how many initial characters
  /// can be removed from the OLC code. The number of characters that can be
  /// removed depends on the distance between the code center and the reference
  /// location.
  /// The minimum number of characters that will be removed is four. If more
  /// than four characters can be removed, the additional characters will be
  /// replaced with the padding character. At most eight characters will be
  /// removed. The reference location must be within 50% of the maximum range.
  /// This ensures that the shortened code will be able to be recovered using
  /// slightly different locations.
  ///
  /// - Parameter code: A full, valid code to shorten.
  /// - Parameter latitude: A latitude, in signed decimal degrees, to use as the
  ///   reference point.
  /// - Parameter longitude: A longitude, in signed decimal degrees, to use as
  ///   the reference point.
  /// - Returns: Either the original code, if the reference location was not
  ///   close enough, or the original.
  @objc(shortenCode:latitude:longitude:)
  public static func shorten(code: String,
                             latitude: Double,
                             longitude: Double) -> String? {
    return OpenLocationCode.shorten(code:code,
                                    latitude:latitude,
                                    longitude:longitude)
  }
}

/// Coordinates of a decoded Open Location Code.
/// The coordinates include the latitude and longitude of the lower left and
/// upper right corners and the center of the bounding box for the area the
/// code represents.
@objc public class OLCArea: NSObject {
  /// The latitude of the SW corner in degrees.
  @objc public var latitudeLo: Double = 0
  /// The longitude of the SW corner in degrees.
  @objc public var longitudeLo: Double = 0
  /// The latitude of the NE corner in degrees.
  @objc public var latitudeHi: Double = 0
  /// The longitude of the NE corner in degrees.
  @objc public var longitudeHi: Double = 0
  /// The number of significant characters that were in the code.
  /// This excludes the separator.
  @objc public var codeLength: Int = 0
  /// The latitude of the center in degrees.
  @objc public var latitudeCenter: Double = 0
  /// latitude_center: The latitude of the center in degrees.
  @objc public var longitudeCenter: Double = 0

  /// - Parameter latitudeLo: The latitude of the SW corner in degrees.
  /// - Parameter longitudeLo: The longitude of the SW corner in degrees.
  /// - Parameter latitudeHi: The latitude of the NE corner in degrees.
  /// - Parameter longitudeHi: The longitude of the NE corner in degrees.
  /// - Parameter codeLength: The number of significant characters that were in
  ///   the code.
  @objc init(latitudeLo: Double,
       longitudeLo: Double,
       latitudeHi: Double,
       longitudeHi: Double,
       codeLength: Int) {
    self.latitudeLo = latitudeLo
    self.longitudeLo = longitudeLo
    self.latitudeHi = latitudeHi
    self.longitudeHi = longitudeHi
    self.codeLength = codeLength
    self.latitudeCenter = min(latitudeLo + (latitudeHi - latitudeLo) / 2,
                              kLatitudeMax)
    self.longitudeCenter = min(longitudeLo + (longitudeHi - longitudeLo) / 2,
                               kLongitudeMax)
  }
  init(_ area: OpenLocationCodeArea) {
    self.latitudeLo = area.latitudeLo
    self.longitudeLo = area.longitudeLo
    self.latitudeHi = area.latitudeHi
    self.longitudeHi = area.longitudeHi
    self.codeLength = area.codeLength
    self.latitudeCenter = area.latitudeCenter
    self.longitudeCenter = area.longitudeCenter
  }

  // Returns lat/lng coordinate array representing the area's center point.
  @objc func latlng() -> Array<Double>{
    return [self.latitudeCenter, self.longitudeCenter]
  }
}

#endif
