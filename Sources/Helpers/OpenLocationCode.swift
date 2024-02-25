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
//  Authored by William Denniss. Ported from openlocationcode.py.
//
//===----------------------------------------------------------------------===//

import Foundation

/// A separator used to break the code into two parts to aid memorability.
let kSeparator: Character = "+"

/// String representation of kSeparator.
let kSeparatorString = String(kSeparator)

/// The number of characters to place before the separator.
let kSeparatorPosition = 8

/// The character used to pad codes.
let kPaddingCharacter: Character = "0"

/// String representation of kPaddingCharacter.
let kPaddingCharacterString = String(kPaddingCharacter)

/// The character set used to encode the values.
let kCodeAlphabet = "23456789CFGHJMPQRVWX"

/// CharacterSet representation of kCodeAlphabet.
let kCodeAlphabetCharset = CharacterSet.init(charactersIn: kCodeAlphabet)

/// The base to use to convert numbers to/from.
let kEncodingBase:UInt32 = UInt32(kCodeAlphabet.count)

/// The maximum value for latitude in degrees.
let kLatitudeMax = 90.0

/// The maximum value for longitude in degrees.
let kLongitudeMax = 180.0

/// Maximum code length using lat/lng pair encoding. The area of such a
/// code is approximately 13x13 meters (at the equator), and should be suitable
/// for identifying buildings. This excludes prefix and separator characters.
let kPairCodeLength = 10

/// The resolution values in degrees for each position in the lat/lng pair
/// encoding. These give the place value of each position, and therefore the
/// dimensions of the resulting area.  Each value is the previous, divided
/// by the base (kCodeAlphabet.length).
let kPairResolutions = [20.0, 1.0, 0.05, 0.0025, 0.000125]

/// Number of columns in the grid refinement method.
let kGridColumns:Int = 4;

/// Number of rows in the grid refinement method.
let kGridRows:Int = 5;

/// Size of the initial grid in degrees.
let kGridSizeDegrees = 0.000125

/// Minimum length of a code that can be shortened.
let kMinTrimmableCodeLen = 6

/// Space/padding characters. Unioned with kCodeAlphabet, forms the
/// complete valid charset for Open Location Codes.
let kLegalCharacters = CharacterSet.init(charactersIn: "23456789CFGHJMPQRVWX+0")

/// Default length of encoded Open Location Codes (not including + symbol).
public let kDefaultFullCodeLength = 11

/// The maximum significant digits in a plus code.
let kMaxCodeLength = 15

/// Default truncation amount for short codes.
public let kDefaultShortCodeTruncation = 4

/// Minimum amount to truncate a short code if it will be truncated.
/// Avoids creating short codes that are not really worth the shortening (i.e.
/// chars saved doesn't make up for need to resolve).
let kMinShortCodeTruncation = 4

/// Coordinates of a decoded Open Location Code.
/// The coordinates include the latitude and longitude of the lower left and
/// upper right corners and the center of the bounding box for the area the
/// code represents.
public struct OpenLocationCodeArea {
  /// The latitude of the SW corner in degrees.
  public let latitudeLo: Double
  /// The longitude of the SW corner in degrees.
  public let longitudeLo: Double
  /// The latitude of the NE corner in degrees.
  public let latitudeHi: Double
  /// The longitude of the NE corner in degrees.
  public let longitudeHi: Double
  /// The number of significant characters that were in the code.
  /// This excludes the separator.
  public let codeLength: Int
  /// The latitude of the center in degrees.
  public let latitudeCenter: Double
  /// latitude_center: The latitude of the center in degrees.
  public let longitudeCenter: Double

  /// - Parameter latitudeLo: The latitude of the SW corner in degrees.
  /// - Parameter longitudeLo: The longitude of the SW corner in degrees.
  /// - Parameter latitudeHi: The latitude of the NE corner in degrees.
  /// - Parameter longitudeHi: The longitude of the NE corner in degrees.
  /// - Parameter codeLength: The number of significant characters that were in
  ///   the code.
  init(latitudeLo: Double,
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

  // Returns lat/lng coordinate array representing the area's center point.
  func latlng() -> Array<Double>{
    return [self.latitudeCenter, self.longitudeCenter]
  }
}

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
/// characters, one for latitude and one for longitude, using base 20. Each pair
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
/// NSLog(@"Open Location Code: %@", code);
/// 
/// // Encode a location with specific code length.
/// NSString *code10Digit = [OLCConverter encodeLatitude:37.421908
///                                            longitude:-122.084681
///                                           codeLength:10];
/// NSLog(@"Open Location Code: %@", code10Digit);
/// 
/// // Decode a full code:
/// OLCArea *coord = [OLCConverter decode:@"849VCWC8+Q48"];
/// NSLog(@"Center is %.6f, %.6f", coord.latitudeCenter, coord.longitudeCenter);
/// 
/// // Attempt to trim the first characters from a code:
/// NSString *shortCode = [OLCConverter shortenCode:@"849VCWC8+Q48"
///                                        latitude:37.4
///                                       longitude:-122.0];
/// NSLog(@"Short Code: %@", shortCode);
/// 
/// // Recover the full code from a short code:
/// NSString *recoveredCode = [OLCConverter recoverNearestWithShortcode:@"CWC8+Q48"
///                                                   referenceLatitude:37.4
///                                                  referenceLongitude:-122.1];
/// NSLog(@"Recovered Full Code: %@", recoveredCode);
/// ```
///
public class OpenLocationCode {
  /// Determines if a code is valid.
  /// To be valid, all characters must be from the Open Location Code character
  /// set with at most one separator. The separator can be in any even-numbered
  /// position up to the eighth digit.
  ///
  /// - Parameter code: The Open Location Code to test.
  /// - Returns: true if the code is a valid Open Location Code.
  public static func isValid(code: String) -> Bool {

    // The separator is required.
    let sep = code.find(kSeparatorString)
    if ((code.filter{$0 == kSeparator} as String).count) > 1 {
      return false
    }
    // Is it the only character?
    if code.utf8.count == 1 {
      return false;
    }
    // Is it in an illegal position?
    if sep == -1 || sep > kSeparatorPosition || sep % 2 == 1 {
      return false
    }
    // We can have an even number of padding characters before the separator,
    // but then it must be the final character.
    let pad = code.find(kPaddingCharacterString)
    if pad != -1 {
      // Not allowed to start with them!
      if pad == 0 {
        return false
      }

      // There can only be one group and it must have even length.
      let rpad = code.rfind(kPaddingCharacterString) + 1
      let pads = code.substring(from:pad, to: rpad)
      let padCharCount = (pads.filter{$0 == kPaddingCharacter} as String).count
      if pads.count % 2 == 1
          || padCharCount != pads.count {
       return false
      }
      // Padded codes must end with a separator, make sure it does.
      let padrange = code.range(of: kSeparatorString,
                                options: String.CompareOptions.backwards)!
      if padrange.upperBound != code.endIndex {
        return false
      }
    }
    // If there are characters after the separator, make sure there isn't just
    // one of them (not legal).
    if code.count - sep - 1 == 1 {
      return false
    }
    // Check the code contains only valid characters.
    let invalidChars = kLegalCharacters.inverted
    if code.uppercased().rangeOfCharacter(from: invalidChars) != nil {
      return false
    }
    return true
  }

  /// Determines if a code is a valid short code.
  /// A short Open Location Code is a sequence created by removing four or more
  /// digits from an Open Location Code. It must include a separator
  /// character.
  ///
  /// - Parameter code: The Open Location Code to test.
  /// - Returns: true if the code is a short Open Location Code.
  public static func isShort(code: String) -> Bool {
    // Check it's valid.
    if !isValid(code: code) {
      return false
    }
    // If there are less characters than expected before the SEPARATOR.
    let sep = code.find(kSeparatorString)
    if sep >= 0 && sep < kSeparatorPosition {
      return true
    }
    return false
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
  public static func isFull(code: String) -> Bool {

    if !isValid(code: code) {
      return false
    }

    // If it's short, it's not full
    if isShort(code: code) {
      return false
    }

    // Work out what the first latitude character indicates for latitude.
    let firstChar = code.uppercased()[0] // returns Character 'o'
    let firstLatValue =
        Double(kCodeAlphabet.find(String(firstChar))) * Double(kEncodingBase)

    if firstLatValue >= Double(kLatitudeMax) * 2 {
      // The code would decode to a latitude of >= 90 degrees.
      return false
    }

    if code.count > 1 {
      // Work out what the first longitude character indicates for longitude.
      let firstChar = code.uppercased()[1] // returns Character 'o'
      let firstLngValue =
          Double(kCodeAlphabet.find(String(firstChar))) * Double(kEncodingBase)

      if firstLngValue >= Double(kLongitudeMax) * 2 {
        // The code would decode to a longitude of >= 180 degrees.
        return false
      }
    }
    return true
  }

  ///  Clip a latitude into the range -90 to 90.
  ///
  /// - Parameter latitude: A latitude in signed decimal degrees.
  internal static func clipLatitude(_ latitude: Double) -> Double {
    return min(90.0, max(-90.0, latitude))
  }

  /// Compute the latitude precision value for a given code length. Lengths <=
  /// 10 have the same precision for latitude and longitude, but lengths > 10
  /// have different precisions due to the grid method having fewer columns than
  /// rows.
  internal static func computeLatitudePrecision(_ codeLength: Int) -> Double {
    if codeLength <= 10 {
      return pow(Double(20), Double(codeLength / -2 + 2))
    }
    return pow(20.0, -3.0)
           / pow(Double(kGridRows), Double(codeLength - 10))
  }

  /// Normalize a longitude into the range -180 to 180, not including 180.
  ///
  /// - Parameter longitude: A longitude in signed decimal degrees.
  internal static func normalizeLongitude(_ longitude: Double) -> Double {
    var longitude = longitude
    while longitude < -180 {
      longitude += 360
    }
    while longitude >= 180 {
      longitude -= 360
    }
    return longitude
  }

  /// Encode a location into a sequence of OLC lat/lng pairs.
  /// This uses pairs of characters (longitude and latitude in that order) to
  /// represent each step in a 20x20 grid. Each code, therefore, has 1/400th
  /// the area of the previous code.
  ///
  /// - Parameter latitude: A latitude in signed decimal degrees.
  /// - Parameter longitude: A longitude in signed decimal degrees.
  /// - Parameter codeLength: The number of significant digits in the output
  ///   code, not including any separator characters.
  internal static func encodePairs(latitude: Double,
                                   longitude: Double,
                                   codeLength: Int) -> String {

    var code: String = ""
    // Adjust latitude and longitude so they fall into positive ranges.
    var adjustedLatitude = latitude + kLatitudeMax
    var adjustedLongitude = longitude + kLongitudeMax
    // Count digits - can't use string length because it may include a separator
    // character.
    var digitCount = 0
    while digitCount < codeLength {
      // Provides the value of digits in this place in decimal degrees.
      let placeValue = kPairResolutions[digitCount / 2]
      // Do the latitude - gets the digit for this place and subtracts that for
      // the next digit.
      var digitValue:Int = Int(adjustedLatitude / placeValue)
      adjustedLatitude -= Double(digitValue) * placeValue
      code += String(kCodeAlphabet[digitValue])
      digitCount += 1
      // And do the longitude - gets the digit for this place and subtracts that
      // for the next digit.
      digitValue = Int(adjustedLongitude / placeValue)
      adjustedLongitude -= Double(digitValue) * placeValue
      code += String(kCodeAlphabet[digitValue])
      digitCount += 1
      // Should we add a separator here?
      if digitCount == kSeparatorPosition && digitCount < codeLength {
        code += String(kSeparator)
      }
    }
    while code.count < kSeparatorPosition {
      code += "0"
    }
    if code.count == kSeparatorPosition {
      code += String(kSeparator)
    }
    return code
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
  public static func encodeGrid(latitude: Double,
                                longitude: Double,
                                codeLength: Int) -> String {
    var code: String = ""
    var latPlaceValue = kGridSizeDegrees
    var lngPlaceValue = kGridSizeDegrees
    // Adjust latitude and longitude so they fall into positive ranges and
    // get the offset for the required places.
    var adjustedLatitude = latitude + kLatitudeMax
    var adjustedLongitude = longitude + kLongitudeMax
    // To avoid problems with floating point, get rid of the degrees.
    adjustedLatitude = adjustedLatitude.truncatingRemainder(dividingBy: 1)
    adjustedLongitude = adjustedLongitude.truncatingRemainder(dividingBy: 1)
    adjustedLatitude = adjustedLatitude.truncatingRemainder(dividingBy: latPlaceValue)
    adjustedLongitude = adjustedLongitude.truncatingRemainder(dividingBy: lngPlaceValue)

    for _ in (0..<codeLength) {
      // Work out the row and column.
      let row = Int(adjustedLatitude / (latPlaceValue / Double(kGridRows)))
      let col = Int(adjustedLongitude / (lngPlaceValue / Double(kGridColumns)))
      latPlaceValue /= Double(kGridRows)
      lngPlaceValue /= Double(kGridColumns)
      adjustedLatitude -= Double(row) * latPlaceValue
      adjustedLongitude -= Double(col) * lngPlaceValue
      code += String(kCodeAlphabet[row * kGridColumns + col])
    }
    return code;
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
  ///   `2`, `4`, `6`, `8`, `10`, `11`, `12`, `13`, `14`, and `15`. Values
  ///   above `15` are accepted, but treated as `15`. Lower values
  ///   indicate a larger area, higher values a more precise area.
  ///   You can also shorten a code after encoding for codes used with a
  ///   reference point (e.g. your current location, a city, etc).
  /// - Returns: Open Location Code for the given coordinate.
  public static func encode(latitude: Double,
                            longitude: Double,
                            codeLength: Int = kDefaultFullCodeLength)
                            -> String? {
    if codeLength < 2
      || (codeLength < kPairCodeLength && codeLength % 2 == 1) {
      // 'Invalid Open Location Code length - '
      return nil
    }
    var codeLength = codeLength
    codeLength = min(codeLength, kMaxCodeLength)

    // Ensure that latitude and longitude are valid.
    var latitude = clipLatitude(latitude)
    let longitude = normalizeLongitude(longitude)

    // Latitude 90 needs to be adjusted to be just less, so the returned code
    // can also be decoded.
    if latitude == 90 {
      latitude = latitude - Double(computeLatitudePrecision(codeLength))
    }
    var code = encodePairs(latitude: latitude,
                           longitude: longitude,
                           codeLength: min(codeLength, kPairCodeLength))
    // If the requested length indicates we want grid refined codes.
    if codeLength > kPairCodeLength {
      code = code + encodeGrid(latitude: latitude,
                               longitude: longitude,
                               codeLength: codeLength - kPairCodeLength)
    }
    return code
  }

  /// Decode an OLC code made up of lat/lng pairs.
  /// This decodes an OLC code made up of alternating latitude and longitude
  /// characters, encoded using base 20.
  ///
  /// - Parameter code: A valid OLC code, presumed to be full, but with the
  ///   separator removed.
  internal static func decodePairs(_ code: String) -> OpenLocationCodeArea? {

    // Get the latitude and longitude values. These will need correcting from
    // positive ranges.
    let latitude = decodePairsSequence(code: code, offset: 0)!
    let longitude = decodePairsSequence(code: code, offset: 1)!
    // Correct the values and set them into the CodeArea object.
    return OpenLocationCodeArea(latitudeLo: latitude[0] - kLatitudeMax,
                                longitudeLo: longitude[0] - kLongitudeMax,
                                latitudeHi: latitude[1] - kLatitudeMax,
                                longitudeHi: longitude[1] - kLongitudeMax,
                                codeLength: code.count)
  }

  /// Decode either a latitude or longitude sequence.
  /// This decodes the latitude or longitude sequence of a lat/lng pair
  //  encoding. Starting at the character at position offset, every second
  /// character is decoded and the value returned.
  ///
  /// - Parameter code: A valid OLC code, presumed to be full, with the
  ///   separator removed.
  /// - Parameter offset: The character to start from.
  /// - Returns: A pair of the low and high values. The low value comes from
  ///   decoding the
  ///   characters. The high value is the low value plus the resolution of the
  ///   last position. Both values are offset into positive ranges and will need
  ///   to be corrected before use.
  internal static func decodePairsSequence(code: String,
                                           offset: Int) -> Array<Double>? {
    var i = 0
    var value = 0.0
    while (i * 2 + offset < code.count) {
      let pos = kCodeAlphabet.find(String(code[i * 2 + offset]))
      let value3 = Double(pos) * kPairResolutions[i]
      value += value3
      i += 1
    }
    return [value, value + kPairResolutions[i - 1]]
  }

  /// Decode the grid refinement portion of an OLC code.
  /// This decodes an OLC code using the grid refinement method.
  ///
  /// - Parameter code: A valid OLC code sequence that is only the grid
  ///   refinement portion. This is the portion of a code starting at position
  ///   11.
  internal static func decodeGrid(_ code: String) -> OpenLocationCodeArea? {

    var latitudeLo = 0.0
    var longitudeLo = 0.0
    var latPlaceValue = kGridSizeDegrees
    var lngPlaceValue = kGridSizeDegrees
    var i = 0
    while i < code.count {
      let codeIndex = kCodeAlphabet.find(String(code[i]))
      let row = codeIndex / kGridColumns
      let col = codeIndex % kGridColumns
      latPlaceValue /= Double(kGridRows)
      lngPlaceValue /= Double(kGridColumns)
      latitudeLo += Double(row) * latPlaceValue
      longitudeLo += Double(col) * lngPlaceValue
      i += 1
    }
    return OpenLocationCodeArea(latitudeLo: latitudeLo,
                                longitudeLo: longitudeLo,
                                latitudeHi: latitudeLo + latPlaceValue,
                                longitudeHi: longitudeLo + lngPlaceValue,
                                codeLength: code.count);
  }

  /// Decodes an Open Location Code into the location coordinates.
  /// Returns a OpenLocationCodeArea object that includes the coordinates of the
  /// bounding box - the lower left, center and upper right.
  ///
  /// - Parameter code: The Open Location Code to decode.
  /// - Returns: A CodeArea object that provides the latitude and longitude of
  ///   two of the corners of the area, the center, and the length of the
  ///   original code.
  public static func decode(_ code: String) -> OpenLocationCodeArea? {
    var code = code
    if !isFull(code: code) {
      return nil
    }
    // Strip out separator character (we've already established the code is
    // valid so the maximum is one), padding characters and convert to upper
    // case.
    code = code.uppercased()
    code = String(code.filter {
        kCodeAlphabetCharset.contains(String($0).unicodeScalars.first!)
    })
    // Constrain to max digits (NB. plus symbol already removed).
    if (code.length > kMaxCodeLength) {
      code = code.substring(to:kMaxCodeLength)
    }

    // Decode the lat/lng pair component.
    let codeArea = decodePairs(code[0..<kPairCodeLength])!
    if code.count <= kPairCodeLength {
      return codeArea
    }
    // If there is a grid refinement component, decode that.
    let gridArea = decodeGrid(code.substring(from:kPairCodeLength))!
    let area = OpenLocationCodeArea(
        latitudeLo: codeArea.latitudeLo + gridArea.latitudeLo,
        longitudeLo: codeArea.longitudeLo + gridArea.longitudeLo,
        latitudeHi: codeArea.latitudeLo + gridArea.latitudeHi,
        longitudeHi: codeArea.longitudeLo + gridArea.longitudeHi,
        codeLength: codeArea.codeLength + gridArea.codeLength)
    return area
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
  ///   code, but was a valid full code, it is returned with proper capitalization
  ///   but otherwise unchanged.
  public static func recoverNearest(shortcode: String,
                                    referenceLatitude: Double,
                                    referenceLongitude: Double) -> String? {

    var referenceLatitude = referenceLatitude;
    var referenceLongitude = referenceLongitude;

    // Passed short code is actually a full code.
    if isFull(code: shortcode) {
      return shortcode.uppercased()
    }
    // Passed short code is not valid.
    if !isShort(code: shortcode) {
      return nil
    }
    // Ensure that latitude and longitude are valid.
    referenceLatitude = clipLatitude(referenceLatitude)
    referenceLongitude = normalizeLongitude(referenceLongitude)
    // Clean up the passed code.
    let shortcode = shortcode.uppercased()
    // Compute the number of digits we need to recover.
    let paddingLength = kSeparatorPosition - shortcode.find(kSeparatorString)
    // The resolution (height and width) of the padded area in degrees.
    let resolution: Double = pow(20, Double(2 - (paddingLength / 2)))
    // Distance from the center to an edge (in degrees).
    let halfResolution: Double = resolution / 2.0
    // Encodes the reference location, uses it to fill in the gaps of the
    // given short code, creating a full code, then decodes it.
    guard let encodedReferencePoint =
        encode(latitude: referenceLatitude, longitude: referenceLongitude)
        else {
      return nil
    }
    let expandedCode = encodedReferencePoint[0..<paddingLength] + shortcode
    guard let codeArea = decode(expandedCode) else {
      return nil
    }
    var latitudeCenter = codeArea.latitudeCenter
    var longitudeCenter = codeArea.longitudeCenter

    // How many degrees latitude is the code from the reference? If it is more
    // than half the resolution, we need to move it north or south but keep it
    // within -90 to 90 degrees.
    if referenceLatitude + halfResolution < latitudeCenter
       && latitudeCenter - resolution >= -kLatitudeMax {
        // If the proposed code is more than half a cell north of the reference
        // location, it's too far, and the best match will be one cell south.
        latitudeCenter -= resolution
    } else if referenceLatitude - halfResolution > latitudeCenter
              && latitudeCenter + resolution <= kLatitudeMax {
        // If the proposed code is more than half a cell south of the reference
        // location, it's too far, and the best match will be one cell north.
        latitudeCenter += resolution
    }
    // Adjust longitude if necessary.
    if referenceLongitude + halfResolution < longitudeCenter {
      longitudeCenter -= resolution
    } else if referenceLongitude - halfResolution > longitudeCenter {
      longitudeCenter += resolution
    }

    return encode(latitude: latitudeCenter,
                  longitude: longitudeCenter,
                  codeLength: codeArea.codeLength)
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
  public static func shorten(code: String,
                             latitude: Double,
                             longitude: Double,
        maximumTruncation: Int = kDefaultShortCodeTruncation)
        -> String? {
    if !isFull(code: code) {
      // Passed code is not valid and full
      return nil
    }
    if code.find(kPaddingCharacterString) != -1 {
      // Cannot shorten padded codes
      return nil
    }
    let code = code.uppercased()
    let codeArea = decode(code)
    if codeArea!.codeLength < kMinTrimmableCodeLen {
      // Code length must be at least kMinTrimmableCodeLen
      return nil
    }
    // Ensure that latitude and longitude are valid.
    let latitude = clipLatitude(latitude)
    let longitude = normalizeLongitude(longitude)
    // How close are the latitude and longitude to the code center.
    let coderange = max(abs(codeArea!.latitudeCenter - latitude),
                        abs(codeArea!.longitudeCenter - longitude))

    for i in stride(from: kPairResolutions.count - kMinShortCodeTruncation/2,
                    to: 0,
                    by: -1) {
      // Check if we're close enough to shorten. The range must be less than 1/2
      // the resolution to shorten at all, and we want to allow some safety, so
      // use 0.3 instead of 0.5 as a multiplier.
      if coderange < (kPairResolutions[i] * 0.3) {
        let shortenby = min(maximumTruncation, (i+1)*2)
        // Trim it.
        let shortcode = code.substring(from: shortenby)
        return shortcode
      }
    }
    return code
  }
}

/// Several extensions to String for character manipulation.
extension String {

  var length: Int {
    return self.count
  }

  subscript (i: Int) -> Character {
    let start = index(self.startIndex, offsetBy: i)
    return self[start]
  }

  func substring(from: Int) -> String {
    return self[min(from, length) ..< length]
  }

  func substring(to: Int) -> String {
    return self[0 ..< max(0, to)]
  }

    subscript (r: Swift.Range<Int>) -> String {
    let lower = max(0, min(length, r.lowerBound))
    let upper = min(length, max(0, r.upperBound))
    let range = Swift.Range(uncheckedBounds: (lower: lower, upper: upper))
    let start = index(startIndex, offsetBy: range.lowerBound)
    let end = index(start, offsetBy: range.upperBound - range.lowerBound)
    return String(self[start ..< end])
  }

  /// Returns index of the first instance of the string, or -1 if not found.
  func find(_ needle: String) -> Int {
    let range = self.range(of: needle)
    if range != nil {
      return self.distance(from: self.startIndex, to: range!.lowerBound)
    }
    return -1
  }

  /// Returns index of the last instance of the string, or -1 if not found.
  func rfind(_ needle: String) -> Int {
    let range = self.range(of: needle, options: String.CompareOptions.backwards)
    if range != nil {
      return self.distance(from: self.startIndex, to: range!.lowerBound)
    }
    return -1
  }

  func substring(from: Int, to: Int) -> String {
    let start = self.index(self.startIndex, offsetBy: from)
    let end = self.index(self.startIndex, offsetBy: to)
    let range = start..<end
    return String(self[range])
  }
    
    func appendingPathComponent(_ str: String) -> String {
        (self as NSString).appendingPathComponent(str)
    }
    
    func appendingPathExtension(_ str: String) -> String {
        (self as NSString).appendingPathExtension(str) ?? self
    }
    
    func lastPathComponent() -> String {
        (self as NSString).lastPathComponent
    }
    
    func deletingPathExtension() -> String {
        (self as NSString).deletingPathExtension
    }
    
    func deletingLastPathComponent() -> String {
        (self as NSString).deletingLastPathComponent
    }
    
}
