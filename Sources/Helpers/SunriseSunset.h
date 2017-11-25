//
//  SunriseSunset.h
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

/******************************************************************************
 *
 *                            SunriseSunset.java
 *
 *******************************************************************************
 *
 * Java Class: SunriseSunset
 *
 *    This Java class is part of a collection of classes developed for the
 *    reading and processing of oceanographic and meterological data collected
 *    since 1970 by environmental buoys and stations.  This dataset is
 *    maintained by the National Oceanographic Data Center and is publicly
 *    available.  These Java classes were written for the US Environmental
 *    Protection Agency's National Exposure Research Laboratory under Contract
 *    No. GS-10F-0073K with Neptune and Company of Los Alamos, New Mexico.
 *
 * Purpose:
 *
 *     This Java class performs calculations to determine the time of
 *    sunrise and sunset given lat, long, and date.
 *
 * Inputs:
 *
 *     Latitude, longitude, date/time, and time zone.
 *
 * Outputs:
 *
 *     Local time of sunrise and sunset as calculated by the
 *      program.
 *    If no sunrise or no sunset occurs, or if the sun is up all day
 *      or down all day, appropriate boolean values are set.
 *    A boolean is provided to identify if the time provided is during the day.
 *
 *    The above values are accessed by the following methods:
 *
 *        Date    getSunrise()    returns date/time of sunrise
 *        Date    getSunset()        returns date/time of sunset
 *        boolean    isSunrise()        returns true if there was a sunrise, else false
 *        boolean    isSunset()        returns true if there was a sunset, else false
 *        boolean    isSunUp()        returns true if sun is up all day, else false
 *        boolean    isSunDown()        returns true if sun is down all day, else false
 *        boolean    isDaytime()        returns true if sun is up at the time
 *                                    specified, else false
 *
 * Required classes from the Java library:
 *
 *     java.util.Date
 *     java.text.SimpleDateFormat
 *     java.text.ParseException;
 *     java.math.BigDecimal;
 *
 * Package of which this class is a member:
 *
 *    default
 *
 * Known limitations:
 *
 *    It is assumed that the data provided are within value ranges
 *    (i.e. latitude between -90 and +90, longitude between 0 and 360,
 *    a valid date, and time zone between -14 and +14.
 *
 * Compatibility:
 *
 *    Java 1.1.8
 *
 * References:
 *
 *    The mathematical algorithms used in this program are patterned
 *    after those debveloped by Roger Sinnott in his BASIC program,
 *    SUNUP.BAS, published in Sky & Telescope magazine:
 *    Sinnott, Roger W. "Sunrise and Sunset: A Challenge"
 *    Sky & Telescope, August, 1994 p.84-85
 *
 *    The following is a cross-index of variables used in SUNUP.BAS.
 *    A single definition from multiple reuse of variable names in
 *    SUNUP.BAS was clarified with various definitions in this program.
 *
 *    SUNUP.BAS    this class
 *
 *    A            dfA
 *    A(2)        dfAA1, dfAA2
 *    A0            dfA0
 *    A2            dfA2
 *    A5            dfA5
 *    AZ            Not used
 *    C            dfCosLat
 *    C0            dfC0
 *    D            iDay
 *    D(2)        dfDD1, dfDD2
 *    D0            dfD0
 *    D1            dfD1
 *    D2            dfD2
 *    D5            dfD5
 *    D7            Not used
 *    DA            dfDA
 *    DD            dfDD
 *    G            bGregorian, dfGG
 *    H            dfTimeZone
 *    H0            dfH0
 *    H1            dfH1
 *    H2            dfH2
 *    H3            dfHourRise, dfHourSet
 *    H7            Not used
 *    J            dfJ
 *    J3            dfJ3
 *    K1            dfK1
 *    L            dfLL
 *    L0            dfL0
 *    L2            dfL2
 *    L5            dfLon
 *    M            iMonth
 *    M3            dfMinRise, dfMinSet
 *    N7            Not used
 *    P            dfP
 *    S            iSign, dfSinLat, dfSS
 *    T            dfT
 *    T0            dfT0
 *    T3            not used
 *    TT            dfTT
 *    U            dfUU
 *    V            dfVV
 *    V0            dfV0
 *    V1            dfV1
 *    V2            dfV2
 *    W            dfWW
 *    Y            iYear
 *    Z            dfZenith
 *    Z0            dfTimeZone
 *
 *
 * Author/Company:
 *
 *     JDT: John Tauxe, Neptune and Company
 *    JMG: Jo Marie Green
 *
 * Change log:
 *
 *    date       ver    by    description of change
 *    _________  _____  ___    ______________________________________________
 *     5 Jan 01  0.006  JDT    Excised from ssapp.java v. 0.005.
 *    11 Jan 01  0.007  JDT    Minor modifications to comments based on
 *                              material from Sinnott, 1994.
 *     7 Feb 01  0.008  JDT    Fixed backwards time zone.  The standard is that
 *                              local time zone is specified in hours EAST of
 *                              Greenwich, so that EST would be -5, for example.
 *                              For some reason, SUNUP.BAS does this backwards
 *                              (probably an americocentric perspective) and
 *                              SunriseSunset adopted that convention.  Oops.
 *                              So the sign in the math is changed.
 *     7 Feb 01  0.009  JDT    Well, that threw off the azimuth calculation...
 *                              Removed the azimuth calculations.
 *    14 Feb 01  0.010  JDT    Added ability to accept a time (HH:mm) in
 *                              dateInput, and decide if that time is daytime
 *                              or nighttime.
 *    27 Feb 01  0.011  JDT    Added accessor methods in place of having public
 *                              variables to get results.
 *    28 Feb 01  0.012  JDT    Cleaned up list of imported classes.
 *    28 Mar 01  1.10   JDT    Final version accompanying deliverable 1b.
 *    4 Apr 01  1.11   JDT    Moved logic supporting .isDaytime into method.
 *                              Moved calculations out of constructor.
 *   01 May 01  1.12   JMG   Added 'GMT' designation and testing lines.
 *   16 May 01  1.13   JDT   Added setLenient( false ) and setTimeZone( tz )
 *                           to dfmtDay, dfmtMonth, and dfmtYear in
 *                            doCalculations.
 *   27 Jun 01  1.14   JDT    Removed reliance on StationConstants (GMT).
 *    13 Aug 01  1.20   JDT    Final version accompanying deliverable 1c.
 *     6 Sep 01  1.21   JDT    Thorough code and comment review.
 *    21 Sep 01  1.30   JDT    Final version accompanying deliverable 2.
 *    17 Dec 01  1.40   JDT    Version accompanying final deliverable.
 *
 *----------------------------------------------------------------------------*/

/******************************************************************************
 *    class:                    SunriseSunset class
 *******************************************************************************
 *
 *     This Java class performs calculations to determine the time of
 *    sunrise and sunset given lat, long, and date.
 *
 *    It is assumed that the data provided are within value ranges
 *    (i.e. latitude between -90 and +90, longitude between 0 and 360,
 *    a valid date, and time zone between -14 and +14.
 *
 *----------------------------------------------------------------------------*/

#import <Foundation/Foundation.h>

@interface SunriseSunset : NSObject

- (instancetype) initWithLatitude:(double)dfLatIn longitude:(double)dfLonIn dateInputIn:(NSDate *)dateInputIn tzIn:(NSTimeZone *)tzIn;

- (BOOL) isDaytime;
- (NSDate *) getSunrise;
- (NSDate *) getSunset;

@end
