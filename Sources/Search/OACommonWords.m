//
//  OACommonWords.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACommonWords.h"

static NSMutableDictionary<NSString *, NSNumber *> *commonWordsDictionary;

@implementation OACommonWords

+ (void) addCommon:(NSString *)string
{
    [commonWordsDictionary setObject:[NSNumber numberWithInteger:commonWordsDictionary.count] forKey:string];
}

+ (int) getCommon:(NSString *)name
{
    //		if(true) {
    //			// not ready for old versions yet
    //			return -1;
    //		}
    NSNumber *i = [commonWordsDictionary objectForKey:name];
    return i == nil ? -1 : i.intValue;
}

+ (int) getCommonSearch:(NSString *)name
{
    NSNumber *i = [commonWordsDictionary objectForKey:name];
    return i == nil ? -1 : i.intValue;
}

+ (int) getCommonGeocoding:(NSString *)name
{
    NSNumber *i = [commonWordsDictionary objectForKey:name];
    return i == nil ? -1 : i.intValue;
}

+ (void) initialize
{
    if (self == [OACommonWords class])
    {
        [self addCommon:@"la"];
        [self addCommon:@"via"];
        [self addCommon:@"rua"];
        [self addCommon:@"de"];
        [self addCommon:@"du"];
        [self addCommon:@"des"];
        [self addCommon:@"del"];
        [self addCommon:@"am"];
        [self addCommon:@"da"];
        [self addCommon:@"a"];
        [self addCommon:@"der"];
        [self addCommon:@"do"];
        [self addCommon:@"los"];
        [self addCommon:@"di"];
        [self addCommon:@"im"];
        [self addCommon:@"el"];
        [self addCommon:@"e"];
        [self addCommon:@"an"];
        [self addCommon:@"g."];
        [self addCommon:@"rd"];
        [self addCommon:@"dos"];
        [self addCommon:@"dei"];
        [self addCommon:@"b"];
        [self addCommon:@"st"];
        [self addCommon:@"the"];
        [self addCommon:@"las"];
        [self addCommon:@"f"];
        [self addCommon:@"u"];
        [self addCommon:@"jl."];
        [self addCommon:@"j"];
        [self addCommon:@"sk"];
        [self addCommon:@"w"];
        [self addCommon:@"a."];
        [self addCommon:@"of"];
        [self addCommon:@"k"];
        [self addCommon:@"r"];
        [self addCommon:@"h"];
        [self addCommon:@"mc"];
        [self addCommon:@"sw"];
        [self addCommon:@"g"];
        [self addCommon:@"v"];
        [self addCommon:@"m"];
        [self addCommon:@"c."];
        [self addCommon:@"r."];
        [self addCommon:@"ct"];
        [self addCommon:@"e."];
        [self addCommon:@"dr."];
        [self addCommon:@"j."];
        [self addCommon:@"in"];
        [self addCommon:@"al"];
        [self addCommon:@"út"];
        [self addCommon:@"per"];
        [self addCommon:@"ne"];
        [self addCommon:@"p"];
        [self addCommon:@"et"];
        [self addCommon:@"s."];
        [self addCommon:@"f."];
        [self addCommon:@"t"];
        [self addCommon:@"fe"];
        [self addCommon:@"à"];
        [self addCommon:@"i"];
        [self addCommon:@"c"];
        [self addCommon:@"le"];
        [self addCommon:@"s"];
        [self addCommon:@"av."];
        [self addCommon:@"den"];
        [self addCommon:@"dr"];
        [self addCommon:@"y"];
        [self addCommon:@"un"];
        
        
        
        [self addCommon:@"van"];
        [self addCommon:@"road"];
        [self addCommon:@"street"];
        [self addCommon:@"drive"];
        [self addCommon:@"avenue"];
        [self addCommon:@"rue"];
        [self addCommon:@"lane"];
        [self addCommon:@"улица"];
        [self addCommon:@"спуск"];
        [self addCommon:@"straße"];
        [self addCommon:@"chemin"];
        [self addCommon:@"way"];
        
        [self addCommon:@"court"];
        [self addCommon:@"calle"];
        
        [self addCommon:@"place"];
        
        [self addCommon:@"avenida"];
        [self addCommon:@"boulevard"];
        [self addCommon:@"county"];
        [self addCommon:@"route"];
        [self addCommon:@"trail"];
        [self addCommon:@"circle"];
        [self addCommon:@"close"];
        [self addCommon:@"highway"];
        
        [self addCommon:@"strada"];
        [self addCommon:@"impasse"];
        [self addCommon:@"utca"];
        [self addCommon:@"creek"];
        [self addCommon:@"carrer"];
        [self addCommon:@"вулиця"];
        [self addCommon:@"allée"];
        [self addCommon:@"weg"];
        [self addCommon:@"площадь"];
        [self addCommon:@"тупик"];
        
        [self addCommon:@"terrace"];
        [self addCommon:@"jalan"];
        
        [self addCommon:@"parkway"];
        [self addCommon:@"переулок"];
        
        [self addCommon:@"carretera"];
        [self addCommon:@"valley"];
        
        [self addCommon:@"camino"];
        [self addCommon:@"viale"];
        [self addCommon:@"loop"];
        
        [self addCommon:@"bridge"];
        [self addCommon:@"embankment"];
        [self addCommon:@"township"];
        [self addCommon:@"town"];
        [self addCommon:@"village"];
        [self addCommon:@"piazza"];
        [self addCommon:@"della"];
        
        [self addCommon:@"plaza"];
        [self addCommon:@"pasaje"];
        [self addCommon:@"expressway"];
        [self addCommon:@"ruta"];
        [self addCommon:@"square"];
        [self addCommon:@"freeway"];
        [self addCommon:@"line"];
        
        [self addCommon:@"track"];
        
        [self addCommon:@"zum"];
        [self addCommon:@"rodovia"];
        [self addCommon:@"sokak"];
        [self addCommon:@"sur"];
        [self addCommon:@"path"];
        [self addCommon:@"das"];
        
        [self addCommon:@"yolu"];
        
        [self addCommon:@"проспект"];
        
        [self addCommon:@"auf"];
        [self addCommon:@"alley"];
        [self addCommon:@"são"];
        [self addCommon:@"les"];
        [self addCommon:@"delle"];
        [self addCommon:@"paseo"];
        [self addCommon:@"alte"];
        [self addCommon:@"autostrada"];
        [self addCommon:@"iela"];
        [self addCommon:@"autovía"];
        [self addCommon:@"d"];
        [self addCommon:@"ulica"];
        
        [self addCommon:@"na"];
        [self addCommon:@"проезд"];
        [self addCommon:@"n"];
        [self addCommon:@"ул."];
        [self addCommon:@"voie"];
        [self addCommon:@"ring"];
        [self addCommon:@"ruelle"];
        [self addCommon:@"vicolo"];
        [self addCommon:@"avinguda"];
        [self addCommon:@"шоссе"];
        [self addCommon:@"zur"];
        [self addCommon:@"corso"];
        [self addCommon:@"autopista"];
        [self addCommon:@"провулок"];
        [self addCommon:@"broadway"];
        [self addCommon:@"to"];
        [self addCommon:@"passage"];
        [self addCommon:@"sentier"];
        [self addCommon:@"aleja"];
        [self addCommon:@"dem"];
        [self addCommon:@"valle"];
        [self addCommon:@"cruz"];
        
        [self addCommon:@"bypass"];
        [self addCommon:@"rúa"];
        [self addCommon:@"crest"];
        [self addCommon:@"ave"];
        
        [self addCommon:@"expressway)"];
        
        [self addCommon:@"autoroute"];
        [self addCommon:@"crossing"];
        [self addCommon:@"camí"];
        [self addCommon:@"bend"];
        
        [self addCommon:@"end"];
        [self addCommon:@"caddesi"];
        [self addCommon:@"bis"];
        
        [self addCommon:@"ქუჩა"];
        [self addCommon:@"kalea"];
        [self addCommon:@"pass"];
        [self addCommon:@"ponte"];
        [self addCommon:@"cruce"];
        [self addCommon:@"se"];
        [self addCommon:@"au"];
        
        [self addCommon:@"allee"];
        [self addCommon:@"autobahn"];
        [self addCommon:@"väg"];
        [self addCommon:@"sentiero"];
        [self addCommon:@"plaça"];
        [self addCommon:@"o"];
        [self addCommon:@"vej"];
        [self addCommon:@"aux"];
        [self addCommon:@"spur"];
        [self addCommon:@"ringstraße"];
        [self addCommon:@"prospect"];
        [self addCommon:@"m."];
        [self addCommon:@"chaussee"];
        [self addCommon:@"row"];
        [self addCommon:@"link"];
        
        [self addCommon:@"travesía"];
        [self addCommon:@"degli"];
        [self addCommon:@"piazzale"];
        [self addCommon:@"vei"];
        [self addCommon:@"waldstraße"];
        [self addCommon:@"promenade"];
        [self addCommon:@"puente"];
        [self addCommon:@"rond-point"];
        [self addCommon:@"vía"];
        [self addCommon:@"pod"];
        [self addCommon:@"triq"];
        [self addCommon:@"hwy"];
        [self addCommon:@"οδός"];
        [self addCommon:@"dels"];
        [self addCommon:@"and"];
        
        [self addCommon:@"pré"];
        [self addCommon:@"plac"];
        [self addCommon:@"fairway"];
        
        // 		[self addCommon:@"farm-to-market"];
        
        [self addCommon:@"набережная"];
        
        [self addCommon:@"chaussée"];
        
        [self addCommon:@"náměstí"];
        [self addCommon:@"tér"];
        [self addCommon:@"roundabout"];
        [self addCommon:@"lakeshore"];
        [self addCommon:@"lakeside"];
        [self addCommon:@"alle"];
        [self addCommon:@"gasse"];
        [self addCommon:@"str."];
        //		[self addCommon:@"p."];
        [self addCommon:@"ville"];
        [self addCommon:@"beco"];
        [self addCommon:@"platz"];
        
        // 		[self addCommon:@"porto"];
        
        [self addCommon:@"sideroad"];
        [self addCommon:@"pista"];
        
        [self addCommon:@"аллея"];
        [self addCommon:@"бульвар"];
        [self addCommon:@"город"];
        [self addCommon:@"городок"];
        [self addCommon:@"деревня"];
        [self addCommon:@"дер."];
        [self addCommon:@"пос."];
        [self addCommon:@"дорога"];
        [self addCommon:@"дорожка"];
        [self addCommon:@"кольцо"];
        [self addCommon:@"мост"];
        [self addCommon:@"остров"];
        [self addCommon:@"островок"];
        [self addCommon:@"поселок"];
        [self addCommon:@"посёлок"];
        [self addCommon:@"путепровод"];
        [self addCommon:@"слобода"];
        [self addCommon:@"станция"];
        [self addCommon:@"тоннель"];
        [self addCommon:@"тракт"];
        [self addCommon:@"island"];
        [self addCommon:@"islet"];
        [self addCommon:@"tunnel"];
        [self addCommon:@"stadt"];
        [self addCommon:@"brücke"];
        [self addCommon:@"damm"];
        [self addCommon:@"insel"];
        [self addCommon:@"dorf"];
        [self addCommon:@"bereich"];
        [self addCommon:@"überführung"];
        [self addCommon:@"bulevar"];
        [self addCommon:@"ciudad"];
        [self addCommon:@"pueblo"];
        [self addCommon:@"anillo"];
        [self addCommon:@"muelle"];
        [self addCommon:@"isla"];
        [self addCommon:@"islote"];
        [self addCommon:@"carril"];
        [self addCommon:@"viaje"];
        [self addCommon:@"città"];
        [self addCommon:@"paese"];
        [self addCommon:@"villaggio"];
        [self addCommon:@"banchina"];
        [self addCommon:@"isola"];
        [self addCommon:@"isolotto"];
        [self addCommon:@"corsia"];
        [self addCommon:@"viaggio"];
        [self addCommon:@"canale"];
        [self addCommon:@"pont"];
        [self addCommon:@"quai"];
        [self addCommon:@"île"];
        [self addCommon:@"îlot"];
        [self addCommon:@"voyage"];
        [self addCommon:@"descente"];
        [self addCommon:@"straat"];
        [self addCommon:@"stad"];
        [self addCommon:@"dorp"];
        [self addCommon:@"brug"];
        [self addCommon:@"kade"];
        [self addCommon:@"eiland"];
        [self addCommon:@"eilandje"];
        [self addCommon:@"laan"];
        [self addCommon:@"plein"];
        [self addCommon:@"reizen"];
        [self addCommon:@"afkomst"];
        [self addCommon:@"kanaal"];
        [self addCommon:@"doodlopende"];
        [self addCommon:@"stradă"];
        [self addCommon:@"rutier"];
        [self addCommon:@"alee"];
        [self addCommon:@"municipiu"];
        [self addCommon:@"oras"];
        [self addCommon:@"drumuri"];
        [self addCommon:@"poduri"];
        [self addCommon:@"cheu"];
        [self addCommon:@"insula"];
        [self addCommon:@"ostrov"];
        [self addCommon:@"sat"];
        [self addCommon:@"călătorie"];
        [self addCommon:@"coborâre"];
        [self addCommon:@"statie"];
        [self addCommon:@"tunel"];
        [self addCommon:@"fundătură"];
        [self addCommon:@"ulice"];
        [self addCommon:@"silnice"];
        [self addCommon:@"bulvár"];
        [self addCommon:@"město"];
        [self addCommon:@"obec"];
        [self addCommon:@"most"];
        [self addCommon:@"nábřeží"];
        [self addCommon:@"ostrova"];
        [self addCommon:@"ostrůvek"];
        [self addCommon:@"lane"];
        [self addCommon:@"vesnice"];
        [self addCommon:@"jezdit"];
        [self addCommon:@"sestup"];
        [self addCommon:@"nádraží"];
        [self addCommon:@"kanál"];
        [self addCommon:@"ulička"];
        [self addCommon:@"gata"];
        [self addCommon:@"by"];
        [self addCommon:@"bro"];
        [self addCommon:@"kaj"];
        [self addCommon:@"ö"];
        [self addCommon:@"holme"];
        [self addCommon:@"fyrkant"];
        [self addCommon:@"resa"];
        [self addCommon:@"härkomst"];
        [self addCommon:@"kanal"];
        [self addCommon:@"återvändsgränd"];
        [self addCommon:@"cesty"];
        [self addCommon:@"ostrovček"];
        [self addCommon:@"námestie"];
        [self addCommon:@"dediny"];
        [self addCommon:@"jazdiť"];
        [self addCommon:@"zostup"];
        [self addCommon:@"stanice"];
        [self addCommon:@"cesta"];
        [self addCommon:@"pot"];
        [self addCommon:@"mesto"];
        [self addCommon:@"kraj"];
        [self addCommon:@"vas"];
        [self addCommon:@"pomol"];
        [self addCommon:@"otok"];
        [self addCommon:@"otoček"];
        [self addCommon:@"trg"];
        [self addCommon:@"potovanje"];
        [self addCommon:@"spust"];
        [self addCommon:@"postaja"];
        [self addCommon:@"predor"];
        [self addCommon:@"вуліца"];
        [self addCommon:@"шаша"];
        [self addCommon:@"алея"];
        [self addCommon:@"горад"];
        [self addCommon:@"мястэчка"];
        [self addCommon:@"вёска"];
        [self addCommon:@"дарога"];
        [self addCommon:@"набярэжная"];
        [self addCommon:@"востраў"];
        [self addCommon:@"астравок"];
        [self addCommon:@"завулак"];
        [self addCommon:@"плошча"];
        [self addCommon:@"пасёлак"];
        [self addCommon:@"праезд"];
        [self addCommon:@"праспект"];
        [self addCommon:@"станцыя"];
        [self addCommon:@"тунэль"];
        [self addCommon:@"тупік"];
        [self addCommon:@"افي."];
        [self addCommon:@"إلى"];
        [self addCommon:@"تسوية"];
        [self addCommon:@"جادة"];
        [self addCommon:@"جزيرة"];
        [self addCommon:@"جسر"];
        [self addCommon:@"زقاق"];
        [self addCommon:@"شارع"];
        [self addCommon:@"طريق"];
        [self addCommon:@"قرية"];
        [self addCommon:@"مأزق"];
        [self addCommon:@"محطة"];
        [self addCommon:@"مدينة"];
        [self addCommon:@"مرور"];
        [self addCommon:@"مسار"];
        [self addCommon:@"ممر"];
        [self addCommon:@"منطقة"];
        [self addCommon:@"نفق"];
        [self addCommon:@"път"];
        [self addCommon:@"булевард"];
        [self addCommon:@"град"];
        [self addCommon:@"село"];
        [self addCommon:@"кей"];
        [self addCommon:@"островче"];
        [self addCommon:@"платно"];
        [self addCommon:@"квадрат"];
        [self addCommon:@"пътуване"];
        [self addCommon:@"произход"];
        [self addCommon:@"гара"];
        [self addCommon:@"тунел"];
        [self addCommon:@"канал"];
        [self addCommon:@"körút"];
        [self addCommon:@"híd"];
        [self addCommon:@"rakpart"];
        [self addCommon:@"állomás"];
        [self addCommon:@"alagút"];
        [self addCommon:@"đường"];
        [self addCommon:@"đại"];
        [self addCommon:@"làng"];
        [self addCommon:@"cầu"];
        [self addCommon:@"đảo"];
        [self addCommon:@"phố"];
        [self addCommon:@"gốc"];
        [self addCommon:@"kênh"];
        [self addCommon:@"δρόμο"];
        [self addCommon:@"λεωφόρος"];
        [self addCommon:@"πόλη"];
        [self addCommon:@"κωμόπολη"];
        [self addCommon:@"χωριό"];
        [self addCommon:@"δρόμος"];
        [self addCommon:@"γέφυρα"];
        [self addCommon:@"αποβάθρα"];
        [self addCommon:@"νησί"];
        [self addCommon:@"νησίδα"];
        [self addCommon:@"λωρίδα"];
        [self addCommon:@"πλατεία"];
        [self addCommon:@"χωριό"];
        [self addCommon:@"ταξίδια"];
        [self addCommon:@"ø"];
        [self addCommon:@"bane"];
    }
}

@end
