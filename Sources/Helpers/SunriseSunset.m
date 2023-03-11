//
//  SunriseSunset.m
//  OsmAnd
//
//  Created by Alexey Kulish on 25/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "SunriseSunset.h"

@implementation SunriseSunset
{
    // Declare and initialize variables
    double    dfLat;                    // latitude from user
    double    dfLon;                    // latitude from user
    NSDate   *dateInput;                // date/time from user
    double    dfTimeZone;                // time zone from user
    
    NSDate   *dateSunrise;            // date and time of sunrise
    NSDate   *dateSunset;                // date and time of sunset
    BOOL      bSunriseToday;    // flag for sunrise on this date
    BOOL      bSunsetToday;    // flag for sunset on this date
    BOOL      bSunUpAllDay;    // flag for sun up all day
    BOOL      bSunDownAllDay;    // flag for sun down all day
    BOOL      bDaytime;    // flag for daytime, given
    BOOL      isNextDay;
    // hour and min in dateInput
    BOOL      bSunrise;        // sunrise during hour checked
    BOOL      bSunset;        // sunset during hour checked
    BOOL      bGregorian;        // flag for Gregorian calendar
    int       iJulian;                // Julian day
    int       iYear;                    // year of date of interest
    int       iMonth;                    // month of date of interest
    int       iDay;                    // day of date of interest
    int       iCount;                    // a simple counter
    int       iSign;                    // SUNUP.BAS: S
    int       dfHourRise, dfHourSet;    // hour of event: SUNUP.BAS H3
    int       dfMinRise, dfMinSet;    // minute of event: SUNUP.BAS M3
    double    dfSinLat, dfCosLat;        // sin and cos of latitude
    double    dfZenith;                // SUNUP.BAS Z: Zenith
    // Many variables in SUNUP.BAS have undocumented meanings,
    // and so are translated rather directly to avoid confusion:
    double    dfAA1;
    double    dfAA2;    // SUNUP.BAS A(2)
    double    dfDD1;
    double    dfDD2;    // SUNUP.BAS D(2)
    double    dfC0;                    // SUNUP.BAS C0
    double    dfK1;                    // SUNUP.BAS K1
    double    dfP;                    // SUNUP.BAS P
    double    dfJ;                    // SUNUP.BAS J
    double    dfJ3;                    // SUNUP.BAS J3
    double    dfA;                    // SUNUP.BAS A
    double    dfA0, dfA2, dfA5;        // SUNUP.BAS A0, A2, A5
    double    dfD0, dfD1, dfD2, dfD5;    // SUNUP.BAS D0, D1, D2, D5
    double    dfDA, dfDD;                // SUNUP.BAS DA, DD
    double    dfH0, dfH1, dfH2;        // SUNUP.BAS H0, H1, H2
    double    dfL0, dfL2;                // SUNUP.BAS L0, L2
    double    dfT, dfT0, dfTT;        // SUNUP.BAS T, T0, TT
    double    dfV0, dfV1, dfV2;        // SUNUP.BAS V0, V1, V2
}

- (instancetype) initWithLatitude:(double)dfLatIn longitude:(double)dfLonIn dateInputIn:(NSDate *)dateInputIn tzIn:(NSTimeZone *)tzIn forNextDay:(BOOL)nextDay
{
    self = [super init];
    if (self)
    {
        bSunriseToday  = false;    // flag for sunrise on this date
        bSunsetToday   = false;    // flag for sunset on this date
        bSunUpAllDay   = false;    // flag for sun up all day
        bSunDownAllDay = false;    // flag for sun down all day
        bDaytime       = false;    // flag for daytime, given
        // hour and min in dateInput
        bSunrise = false;        // sunrise during hour checked
        bSunset  = false;        // sunset during hour checked
        bGregorian = false;
        isNextDay = nextDay;
        
        dfAA1 = 0;
        dfAA2 = 0;
        dfDD1 = 0;
        dfDD2 = 0;
        
        // Calculate internal representation of timezone offset as fraction of hours from GMT
        // Our calculations consider offsets to the West as positive, so we must invert
        // the signal of the values provided by the standard library
        double dfTimeZoneIn = 1.0 * [tzIn secondsFromGMTForDate:dateInputIn] / 3600.0;
        
        // Copy values supplied as agruments to local variables.
        dfLat         = dfLatIn;
        dfLon         = dfLonIn;
        dateInput     = dateInputIn;
        dfTimeZone     = dfTimeZoneIn;
        
        // Call the method to do the calculations.
        [self doCalculations];
    }
    return self;
}

- (void) doCalculations
{
    // Break out day, month, and year from date provided using local time zone.
    // (This is necessary for the math algorithms.)
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:[NSDate date]];
    iYear = (int) [components year];
    iMonth = (int) [components month];
    if (isNextDay)
        iDay = (int) [components day] + 1;
    else
        iDay = (int) [components day];
        
    // Convert time zone hours to decimal days (SUNUP.BAS line 50)
    dfTimeZone = dfTimeZone / 24.0;
    
    // NOTE: (7 Feb 2001) Here is a non-standard part of SUNUP.BAS:
    // It (and this algorithm) assumes that the time zone is
    // positive west, instead of the standard negative west.
    // Classes calling SunriseSunset will be assuming that
    // times zones are specified in negative west, so here the
    // sign is changed so that the SUNUP algorithm works:
    dfTimeZone = -dfTimeZone;
    
    // Convert longitude to fraction (SUNUP.BAS line 50)
    dfLon = dfLon / 360.0;
    
    // Convert calendar date to Julian date:
    // Check to see if it's later than 1583: Gregorian calendar
    // When declared, bGregorian is initialized to false.
    // ** Consider making a separate class of this function. **
    if( iYear >= 1583 ) bGregorian = true;
    // SUNUP.BAS 1210
    dfJ = -floor( 7.0        // SUNUP used INT, not floor
                      * ( floor(
                                     ( iMonth + 9.0 )
                                     / 12.0
                                     ) + iYear
                         ) / 4.0
                      )
    // add SUNUP.BAS 1240 and 1250 for G = 0
    + floor( iMonth * 275.0 / 9.0 )
    + iDay
    + 1721027.0
    + iYear * 367.0;
    
    if ( bGregorian )
    {
        // SUNUP.BAS 1230
        if ( ( iMonth - 9.0 ) < 0.0 ) iSign = -1;
        else iSign = 1;
        dfA = ABS( iMonth - 9.0 );
        // SUNUP.BAS 1240 and 1250
        dfJ3 = -floor(
                           (
                            floor(
                                       floor( iYear
                                                  + (double)iSign
                                                  * floor( dfA / 7.0 )
                                                  )
                                       / 100.0
                                       ) + 1.0
                            ) * 0.75
                           );
        // correct dfJ as in SUNUP.BAS 1240 and 1250 for G = 1
        dfJ = dfJ + dfJ3 + 2.0;
    }
    // SUNUP.BAS 1290
    iJulian = (int)dfJ - 1;
    
    // SUNUP.BAS 60 and 70 (see also line 1290)
    dfT = (double)iJulian - 2451545.0 + 0.5;
    dfTT = dfT / 36525.0 + 1.0;                // centuries since 1900
    
    // Calculate local sidereal time at 0h in zone time
    // SUNUP.BAS 410 through 460
    dfT0 = ( dfT * 8640184.813 / 36525.0
            + 24110.5
            + dfTimeZone * 86636.6
            + dfLon * 86400.0
            )
    / 86400.0;
    dfT0 = dfT0 - floor( dfT0 );    // NOTE: SUNUP.BAS uses INT()
    dfT0 = dfT0 * 2.0 * M_PI;
    // SUNUP.BAS 90
    dfT = dfT + dfTimeZone;
    
    // SUNUP.BAS 110: Get Sun's position
    for( iCount=0; iCount<=1; iCount++ )    // Loop thru only twice
    {
        // Calculate Sun's right ascension and declination
        //   at the start and end of each day.
        // SUNUP.BAS 910 - 1160: Fundamental arguments
        //   from van Flandern and Pulkkinen, 1979
        
        // declare local temporary doubles for calculations
        double    dfGG;                        // SUNUP.BAS G
        double    dfLL;                        // SUNUP.BAS L
        double    dfSS;                        // SUNUP.BAS S
        double    dfUU;                        // SUNUP.BAS U
        double    dfVV;                        // SUNUP.BAS V
        double    dfWW;                        // SUNUP.BAS W
        
        dfLL = 0.779072 + 0.00273790931 * dfT;
        dfLL = dfLL - floor( dfLL );
        dfLL = dfLL * 2.0 * M_PI;
        
        dfGG = 0.993126 + 0.0027377785 * dfT;
        dfGG = dfGG - floor( dfGG );
        dfGG = dfGG * 2.0 * M_PI;
        
        dfVV =   0.39785 * sin( dfLL )
        - 0.01000 * sin( dfLL - dfGG )
        + 0.00333 * sin( dfLL + dfGG )
        - 0.00021 * sin( dfLL ) * dfTT;
        
        dfUU = 1
        - 0.03349 * cos( dfGG )
        - 0.00014 * cos( dfLL * 2.0 )
        + 0.00008 * cos( dfLL );
        
        dfWW = - 0.00010
        - 0.04129 * sin( dfLL * 2.0 )
        + 0.03211 * sin( dfGG )
        - 0.00104 * sin( 2.0 * dfLL - dfGG )
        - 0.00035 * sin( 2.0 * dfLL + dfGG )
        - 0.00008 * sin( dfGG ) * dfTT;
        
        // Compute Sun's RA and Dec; SUNUP.BAS 1120 - 1140
        dfSS = dfWW / sqrt( dfUU - dfVV * dfVV );
        dfA5 = dfLL
        + atan( dfSS / sqrt( 1.0 - dfSS * dfSS ));
        
        dfSS = dfVV / sqrt( dfUU );
        dfD5 = atan( dfSS / sqrt( 1 - dfSS * dfSS ));
        
        // Set values and increment t
        if ( iCount == 0 )        // SUNUP.BAS 125
        {
            dfAA1 = dfA5;
            dfDD1 = dfD5;
        }
        else                    // SUNUP.BAS 145
        {
            dfAA2 = dfA5;
            dfDD2 = dfD5;
        }
        dfT = dfT + 1.0;        // SUNUP.BAS 130
    }    // end of Get Sun's Position for loop
    
    if ( dfAA2 < dfAA1 ) dfAA2 = dfAA2 + 2.0 * M_PI;
    // SUNUP.BAS 150
    
    dfZenith = M_PI * 90.833 / 180.0;            // SUNUP.BAS 160
    dfSinLat = sin( dfLat * M_PI / 180.0 );    // SUNUP.BAS 170
    dfCosLat = cos( dfLat * M_PI / 180.0 );    // SUNUP.BAS 170
    
    dfA0 = dfAA1;                                    // SUNUP.BAS 190
    dfD0 = dfDD1;                                    // SUNUP.BAS 190
    dfDA = dfAA2 - dfAA1;                            // SUNUP.BAS 200
    dfDD = dfDD2 - dfDD1;                            // SUNUP.BAS 200
    
    dfK1 = 15.0 * 1.0027379 * M_PI / 180.0;        // SUNUP.BAS 330
    
    // Initialize sunrise and sunset times, and other variables
    // hr and min are set to impossible times to make errors obvious
    dfHourRise = 99;
    dfMinRise  = 99;
    dfHourSet  = 99;
    dfMinSet   = 99;
    dfV0 = 0.0;        // initialization implied by absence in SUNUP.BAS
    dfV2 = 0.0;        // initialization implied by absence in SUNUP.BAS
    
    // Test each hour to see if the Sun crosses the horizon
    //   and which way it is heading.
    for( iCount=0; iCount<24; iCount++ )            // SUNUP.BAS 210
    {
        double    tempA;                                // SUNUP.BAS A
        double    tempB;                                // SUNUP.BAS B
        double    tempD;                                // SUNUP.BAS D
        double    tempE;                                // SUNUP.BAS E
        
        dfC0 = (double)iCount;
        dfP = ( dfC0 + 1.0 ) / 24.0;                // SUNUP.BAS 220
        dfA2 = dfAA1 + dfP * dfDA;                    // SUNUP.BAS 230
        dfD2 = dfDD1 + dfP * dfDD;                    // SUNUP.BAS 230
        dfL0 = dfT0 + dfC0 * dfK1;                    // SUNUP.BAS 500
        dfL2 = dfL0 + dfK1;                            // SUNUP.BAS 500
        dfH0 = dfL0 - dfA0;                            // SUNUP.BAS 510
        dfH2 = dfL2 - dfA2;                            // SUNUP.BAS 510
        // hour angle at half hour
        dfH1 = ( dfH2 + dfH0 ) / 2.0;                // SUNUP.BAS 520
        // declination at half hour
        dfD1 = ( dfD2 + dfD0 ) / 2.0;                // SUNUP.BAS 530
        
        // Set value of dfV0 only if this is the first hour,
        // otherwise, it will get set to the last dfV2 (SUNUP.BAS 250)
        if ( iCount == 0 )                            // SUNUP.BAS 550
        {
            dfV0 = dfSinLat * sin( dfD0 )
            + dfCosLat * cos( dfD0 ) * cos( dfH0 )
            - cos( dfZenith );            // SUNUP.BAS 560
        }
        else
            dfV0 = dfV2;    // That is, dfV2 from the previous hour.
        
        dfV2 = dfSinLat * sin( dfD2 )
        + dfCosLat * cos( dfD2 ) * cos( dfH2 )
        - cos( dfZenith );            // SUNUP.BAS 570
        
        // if dfV0 and dfV2 have the same sign, then proceed to next hr
        if (
            ( dfV0 >= 0.0 && dfV2 >= 0.0 )        // both are positive
            ||                                // or
            ( dfV0 < 0.0 && dfV2 < 0.0 )         // both are negative
            )
        {
            // Break iteration and proceed to test next hour
            dfA0 = dfA2;                            // SUNUP.BAS 250
            dfD0 = dfD2;                            // SUNUP.BAS 250
            continue;                                // SUNUP.BAS 610
        }
        
        dfV1 = dfSinLat * sin( dfD1 )
        + dfCosLat * cos( dfD1 ) * cos( dfH1 )
        - cos( dfZenith );                // SUNUP.BAS 590
        
        tempA = 2.0 * dfV2 - 4.0 * dfV1 + 2.0 * dfV0;
        // SUNUP.BAS 600
        tempB = 4.0 * dfV1 - 3.0 * dfV0 - dfV2;        // SUNUP.BAS 600
        tempD = tempB * tempB - 4.0 * tempA * dfV0;    // SUNUP.BAS 610
        
        if ( tempD < 0.0 )
        {
            // Break iteration and proceed to test next hour
            dfA0 = dfA2;                            // SUNUP.BAS 250
            dfD0 = dfD2;                            // SUNUP.BAS 250
            continue;                                // SUNUP.BAS 610
        }
        
        tempD = sqrt( tempD );                    // SUNUP.BAS 620
        
        // Determine occurence of sunrise or sunset.
        
        // Flags to identify occurrence during this day are
        // bSunriseToday and bSunsetToday, and are initialized false.
        // These are set true only if sunrise or sunset occurs
        // at any point in the hourly loop. Never set to false.
        
        // Flags to identify occurrence during this hour:
        bSunrise = false;                // reset before test
        bSunset  = false;                // reset before test
        
        if ( dfV0 < 0.0 && dfV2 > 0.0 )    // sunrise occurs this hour
        {
            bSunrise = true;            // SUNUP.BAS 640
            bSunriseToday = true;        // sunrise occurred today
        }
        
        if ( dfV0 > 0.0 && dfV2 < 0.0 )    // sunset occurs this hour
        {
            bSunset = true;                // SUNUP.BAS 660
            bSunsetToday = true;        // sunset occurred today
        }
        
        tempE = ( tempD - tempB ) / ( 2.0 * tempA );
        if ( tempE > 1.0 || tempE < 0.0 )    // SUNUP.BAS 670, 680
            tempE = ( -tempD - tempB ) / ( 2.0 * tempA );
        
        // Set values of hour and minute of sunset or sunrise
        // only if sunrise/set occurred this hour.
        if ( bSunrise )
        {
            dfHourRise = (int)( dfC0 + tempE + 1.0/120.0 );
            dfMinRise  = (int) (
                                ( dfC0 + tempE + 1.0/120.0
                                 - dfHourRise
                                 )
                                * 60.0
                                );
        }
        
        if ( bSunset )
        {
            dfHourSet  = (int) ( dfC0 + tempE + 1.0/120.0 );
            dfMinSet   = (int)(
                               ( dfC0 + tempE + 1.0/120.0
                                - dfHourSet
                                )
                               * 60.0
                               );
        }
        
        // Change settings of variables for next loop
        dfA0 = dfA2;                                // SUNUP.BAS 250
        dfD0 = dfD2;                                // SUNUP.BAS 250
        
    }    // end of loop testing each hour for an event
    
    // After having checked all hours, set flags if no rise or set
    // bSunUpAllDay and bSundownAllDay are initialized as false
    if ( !bSunriseToday && !bSunsetToday )
    {
        if ( dfV2 < 0.0 )
            bSunDownAllDay = true;
        else
            bSunUpAllDay = true;
    }
    
    // Load dateSunrise with data
    
    if( bSunriseToday )
    {
        NSCalendar *c = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = iYear;
        components.month = iMonth;
        components.day = iDay;
        components.hour = dfHourRise;
        components.minute = dfMinRise;
        dateSunrise = [c dateFromComponents:components];
    }
    
    // Load dateSunset with data
    if( bSunsetToday )
    {
        NSCalendar *c = [NSCalendar currentCalendar];
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.year = iYear;
        components.month = iMonth;
        components.day = iDay;
        components.hour = dfHourSet;
        components.minute = dfMinSet;
        dateSunset = [c dateFromComponents:components];
    }
}

/******************************************************************************
 *    method:                    isDaytime()
 *******************************************************************************
 *
 *   Returns a boolean identifying if it is daytime at the hour contained in
 *    the Date object passed to SunriseSunset on construction.
 *
 *    Member of SunriseSunset class
 *
 * -------------------------------------------------------------------------- */
- (BOOL) isDaytime
{
    // Determine if it is daytime (at sunrise or later)
    //    or nighttime (at sunset or later) at the location of interest
    //    but expressed in the time zone requested.
    if ( bSunriseToday && bSunsetToday )     // sunrise and sunset
    {
        if ( [dateSunrise compare:dateSunset] == NSOrderedAscending )    // sunrise < sunset
        {
            if (
                (
                 [dateInput compare:dateSunrise] == NSOrderedDescending
                 ||
                 [dateInput compare:dateSunrise] == NSOrderedSame
                 )
                &&
                [dateInput compare:dateSunset] == NSOrderedAscending
                )
                bDaytime = true;
            else
                bDaytime = false;
        }
        else     // sunrise comes after sunset (in opposite time zones)
        {
            if (
                (
                 [dateInput compare:dateSunrise] == NSOrderedDescending
                 ||
                 [dateInput compare:dateSunrise] == NSOrderedSame
                 )
                ||            // use OR rather than AND
                [dateInput compare:dateSunset] == NSOrderedAscending
                )
                bDaytime = true;
            else
                bDaytime = false;
        }
    }
    else if ( bSunUpAllDay )                 // sun is up all day
        bDaytime = true;
    else if ( bSunDownAllDay )                // sun is down all day
        bDaytime = false;
    else if ( bSunriseToday )                 // sunrise but no sunset
    {
        if ( [dateInput compare:dateSunrise] == NSOrderedAscending )
            bDaytime = false;
        else
            bDaytime = true;
    }
    else if ( bSunsetToday )                 // sunset but no sunrise
    {
        if ( [dateInput compare:dateSunset] == NSOrderedAscending )
            bDaytime = true;
        else
            bDaytime = false;
    }
    else bDaytime = false;                    // this should never execute
    
    return( bDaytime );
}

- (NSDate *) getSunrise
{
    if (bSunriseToday)
        return dateSunrise;
    else
        return nil;
}

- (NSDate *) getSunset
{
    if (bSunsetToday)
        return dateSunset;
    else
        return nil;
}

@end
