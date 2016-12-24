//
//  OAPOIFiltersHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 21/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAPOIFiltersHelper.h"
#import "OAPOIUIFilter.h"
#import "OASearchByNameFilter.h"
#import "Localization.h"
#import "OAPOIHelper.h"
#import "OAUtilities.h"
#import "OAPOIBaseType.h"
#import "OAPOIType.h"

static NSString* const UDF_CAR_AID = @"car_aid";
static NSString* const UDF_FOR_TOURISTS = @"for_tourists";
static NSString* const UDF_FOOD_SHOP = @"food_shop";
static NSString* const UDF_FUEL = @"fuel";
static NSString* const UDF_SIGHTSEEING = @"sightseeing";
static NSString* const UDF_EMERGENCY = @"emergency";
static NSString* const UDF_PUBLIC_TRANSPORT = @"public_transport";
static NSString* const UDF_ACCOMMODATION = @"accommodation";
static NSString* const UDF_RESTAURANTS = @"restaurants";
static NSString* const UDF_PARKING = @"parking";

static const NSArray<NSString *> *DEL = @[UDF_CAR_AID, UDF_FOR_TOURISTS, UDF_FOOD_SHOP, UDF_FUEL, UDF_SIGHTSEEING, UDF_EMERGENCY,
                                         UDF_PUBLIC_TRANSPORT, UDF_ACCOMMODATION, UDF_RESTAURANTS, UDF_PARKING];

@implementation OAPOIFiltersHelper
{
    OAPOIUIFilter *_searchByNamePOIFilter;
    OAPOIUIFilter *_customPOIFilter;
    OAPOIUIFilter *_showAllPOIFilter;
    OAPOIUIFilter *_localWikiPoiFilter;
    NSMutableArray<OAPOIUIFilter *> *_cacheTopStandardFilters;
    NSMutableSet<OAPOIUIFilter *> *_selectedPoiFilters;
    
    OAPOIHelper *_poiHelper;
}

+ (OAPOIFiltersHelper *)sharedInstance
{
    static dispatch_once_t once;
    static OAPOIFiltersHelper * sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cacheTopStandardFilters = [NSMutableArray array];
        _selectedPoiFilters = [NSMutableSet set];
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (OAPOIUIFilter *) getSearchByNamePOIFilter
{
    if (!_searchByNamePOIFilter)
    {
        OAPOIUIFilter *filter = [[OASearchByNameFilter alloc] init];
        filter.isStandardFilter = YES;
        _searchByNamePOIFilter = filter;
    }
    return _searchByNamePOIFilter;
}

- (OAPOIUIFilter *) getCustomPOIFilter
{
    if (!_customPOIFilter)
    {
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithName:OALocalizedString(@"poi_filter_custom_filter") filterId:CUSTOM_FILTER_ID acceptedTypes:[NSDictionary dictionary]];
        filter.isStandardFilter = YES;
        _customPOIFilter = filter;
    }
    return _customPOIFilter;
}

- (OAPOIUIFilter *) getLocalWikiPOIFilter
{
    if (!_localWikiPoiFilter)
    {
        OAPOIType *place = [_poiHelper getPoiTypeByName:@"wiki_place"];
        if (place)
        {
            OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:place idSuffix:[@" " stringByAppendingString:[OAUtilities translatedLangName:[OAUtilities currentLang]]]];
            filter.savedFilterByName = [@"wiki:lang:" stringByAppendingString:[OAUtilities currentLang]];
            filter.isStandardFilter = YES;
            _localWikiPoiFilter = filter;
        }
    }
    return _localWikiPoiFilter;
}

- (OAPOIUIFilter *) getShowAllPOIFilter
{
    if (!_showAllPOIFilter)
    {
        OAPOIUIFilter *filter = [[OAPOIUIFilter alloc] initWithBasePoiType:nil idSuffix:@""];
        filter.isStandardFilter = YES;
        _showAllPOIFilter = filter;
    }
    return _showAllPOIFilter;
}


- (OAPOIUIFilter *) getFilterById:(NSString *)filterId filters:(NSArray<OAPOIUIFilter *> *)filters
{
    for (OAPOIUIFilter *pf in filters)
    {
        if ([pf.filterId isEqualToString:filterId])
            return pf;
    }
    return nil;
}

- (OAPOIUIFilter *) getFilterById:(NSString *)filterId
{
    if (!filterId)
        return nil;

    for (OAPOIUIFilter *f in [self getTopDefinedPoiFilters])
    {
        if ([f.filterId isEqualToString:filterId])
            return f;
    }
    OAPOIUIFilter *ff = [self getFilterById:filterId filters:@[[self getCustomPOIFilter], [self getSearchByNamePOIFilter],
                                                               [self getLocalWikiPOIFilter], [self getShowAllPOIFilter]]];
    if (!ff)
        return ff;

    if ([filterId hasPrefix:STD_PREFIX])
    {
        NSString *typeId = [filterId substringFromIndex:STD_PREFIX.length];
        OAPOIBaseType *tp = [_poiHelper getAnyPoiTypeByName:typeId];
        if (tp)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:tp idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
            [copy addObject:lf];
            [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
            _cacheTopStandardFilters = copy;
            return lf;
        }
        OAPOIBaseType *lt = [_poiHelper getAnyPoiAdditionalTypeByKey:typeId];
        if (lt)
        {
            OAPOIUIFilter *lf = [[OAPOIUIFilter alloc] initWithBasePoiType:lt idSuffix:@""];;
            NSMutableArray<OAPOIUIFilter *> *copy = [NSMutableArray arrayWithArray:_cacheTopStandardFilters];
            [copy addObject:lf];
            [copy sortUsingComparator:[OAPOIUIFilter getComparator]];
            _cacheTopStandardFilters = copy;
            return lf;
        }
    }
    return nil;
}

- (void) reloadAllPoiFilters
{
    _showAllPOIFilter = nil;
    [self getShowAllPOIFilter];
    _cacheTopStandardFilters = nil;
    [self getTopDefinedPoiFilters];
}

- (NSArray<OAPOIUIFilter *> *) getUserDefinedPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *userDefinedFilters = [NSMutableArray array];
    OAPOIFilterDbHelper *helper = [self openDbHelper];
    if (helper)
    {
        NSArray<OAPOIUIFilter *> *userDefined = [helper getFilters:[helper getReadableDatabase]];
        [userDefinedFilters addObjectsFromArray:userDefined];
        [helper close];
    }
    return userDefinedFilters;
}

- (NSArray<OAPOIUIFilter *> *) getSearchPoiFilters
{
    NSMutableArray<OAPOIUIFilter *> *result = [NSMutableArray array];
    NSArray<OAPOIUIFilter *> *filters = @[[self getCustomPOIFilter], /*getShowAllPOIFilter(),*/ [self getSearchByNamePOIFilter]];
    for (OAPOIUIFilter *f : filters)
    {
        if (f && ![f isEmpty])
            [result addObject:f];
    }
    return result;
}

- (NSArray<OAPOIUIFilter *> *) getTopDefinedPoiFilters
{
    if (!_cacheTopStandardFilters)
    {
        NSMutableArray<OAPOIUIFilter *> *top = [NSMutableArray array];
        // user defined
        [top addObjectsFromArray:[self getUserDefinedPoiFilters]];
        if ([self getLocalWikiPOIFilter])
            [top addObjectsFromArray:[self getLocalWikiPOIFilter]];

        // default
        for (OAPOIFilter *t in [_poiHelper getTopVisibleFilters])
        {
            OAPOIUIFilter *f = [[OAPOIUIFilter alloc] initWithBasePoiType:t idSuffix:@""];
            [top addObject:f];
        }
        [top sortUsingComparator:[OAPOIUIFilter getComparator]];
        _cacheTopStandardFilters = top;
    }
    NSMutableArray<OAPOIUIFilter *> *result = [NSMutableArray array];
    [result addObjectsFromArray:_cacheTopStandardFilters];
    [result addObject:[self getShowAllPOIFilter]];
    return result;
}

private PoiFilterDbHelper openDbHelper() {
    if (!application.getPoiTypes().isInit()) {
        return null;
    }
    return new PoiFilterDbHelper(application.getPoiTypes(), application);
}

public boolean removePoiFilter(OAPOIUIFilter * filter) {
    if (filter.getFilterId().equals(OAPOIUIFilter *.CUSTOM_FILTER_ID) ||
        filter.getFilterId().equals(OAPOIUIFilter *.BY_NAME_FILTER_ID) ||
        filter.getFilterId().startsWith(OAPOIUIFilter *.STD_PREFIX)) {
        return false;
    }
    PoiFilterDbHelper helper = openDbHelper();
    if (helper == null) {
        return false;
    }
    boolean res = helper.deleteFilter(helper.getWritableDatabase(), filter);
    if (res) {
        ArrayList<OAPOIUIFilter *> copy = new ArrayList<>(cacheTopStandardFilters);
        copy.remove(filter);
        cacheTopStandardFilters = copy;
    }
    helper.close();
    return res;
}

public boolean createPoiFilter(OAPOIUIFilter * filter) {
    PoiFilterDbHelper helper = openDbHelper();
    if (helper == null) {
        return false;
    }
    boolean res = helper.deleteFilter(helper.getWritableDatabase(), filter);
    Iterator<OAPOIUIFilter *> it = cacheTopStandardFilters.iterator();
    while (it.hasNext()) {
        if (it.next().getFilterId().equals(filter.getFilterId())) {
            it.remove();
        }
    }
    res = helper.addFilter(filter, helper.getWritableDatabase(), false);
    if (res) {
        ArrayList<OAPOIUIFilter *> copy = new ArrayList<>(cacheTopStandardFilters);
        copy.add(filter);
        Collections.sort(copy);
        cacheTopStandardFilters = copy;
    }
    helper.close();
    return res;
}

public boolean editPoiFilter(OAPOIUIFilter * filter) {
    if (filter.getFilterId().equals(OAPOIUIFilter *.CUSTOM_FILTER_ID) ||
        filter.getFilterId().equals(OAPOIUIFilter *.BY_NAME_FILTER_ID) || filter.getFilterId().startsWith(OAPOIUIFilter *.STD_PREFIX)) {
        return false;
    }
    PoiFilterDbHelper helper = openDbHelper();
    if (helper != null) {
        boolean res = helper.editFilter(helper.getWritableDatabase(), filter);
        helper.close();
        return res;
    }
    return false;
}

@NonNull
public Set<OAPOIUIFilter *> getSelectedPoiFilters() {
    return selectedPoiFilters;
}

public void addSelectedPoiFilter(OAPOIUIFilter * filter) {
    selectedPoiFilters.add(filter);
    saveSelectedPoiFilters();
}

public void removeSelectedPoiFilter(OAPOIUIFilter * filter) {
    selectedPoiFilters.remove(filter);
    saveSelectedPoiFilters();
}

public boolean isShowingAnyPoi() {
    return !selectedPoiFilters.isEmpty();
}

public void clearSelectedPoiFilters() {
    selectedPoiFilters.clear();
    saveSelectedPoiFilters();
}

public NSString * getFiltersName(Set<OAPOIUIFilter *> filters) {
    if (filters.isEmpty()) {
        return application.getResources().getString(R.string.shared_string_none);
    } else {
        List<NSString *> names = new ArrayList<>();
        for (OAPOIUIFilter * filter : filters) {
            names.add(filter.getName());
        }
        return android.text.TextUtils.join(", ", names);
    }
}

public NSString * getSelectedPoiFiltersName() {
    return getFiltersName(selectedPoiFilters);
}

public boolean isPoiFilterSelected(OAPOIUIFilter * filter) {
    return selectedPoiFilters.contains(filter);
}

public boolean isPoiFilterSelected(NSString * filterId) {
    for (OAPOIUIFilter * filter : selectedPoiFilters) {
        if (filter.filterId.equals(filterId)) {
            return true;
        }
    }
    return false;
}

public void loadSelectedPoiFilters() {
    Set<NSString *> filters = application.getSettings().getSelectedPoiFilters();
    for (NSString * f : filters) {
        OAPOIUIFilter * filter = getFilterById(f);
        if (filter != null) {
            selectedPoiFilters.add(filter);
        }
    }
}

public void saveSelectedPoiFilters() {
    Set<NSString *> filters = new HashSet<>();
    for (OAPOIUIFilter * f : selectedPoiFilters) {
        filters.add(f.filterId);
    }
    application.getSettings().setSelectedPoiFilters(filters);
}

public class PoiFilterDbHelper {
    
    public static final NSString * DATABASE_NAME = "poi_filters"; //$NON-NLS-1$
    private static final int DATABASE_VERSION = 5;
    private static final NSString * FILTER_NAME = "poi_filters"; //$NON-NLS-1$
    private static final NSString * FILTER_COL_NAME = "name"; //$NON-NLS-1$
    private static final NSString * FILTER_COL_ID = "id"; //$NON-NLS-1$
    private static final NSString * FILTER_COL_FILTERBYNAME = "filterbyname"; //$NON-NLS-1$
    private static final NSString * FILTER_TABLE_CREATE = "CREATE TABLE " + FILTER_NAME + " (" + //$NON-NLS-1$ //$NON-NLS-2$
				FILTER_COL_NAME + ", " + FILTER_COL_ID + ", " + FILTER_COL_FILTERBYNAME + ");"; //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
    
    
    private static final NSString * CATEGORIES_NAME = "categories"; //$NON-NLS-1$
    private static final NSString * CATEGORIES_FILTER_ID = "filter_id"; //$NON-NLS-1$
    private static final NSString * CATEGORIES_COL_CATEGORY = "category"; //$NON-NLS-1$
    private static final NSString * CATEGORIES_COL_SUBCATEGORY = "subcategory"; //$NON-NLS-1$
    private static final NSString * CATEGORIES_TABLE_CREATE = "CREATE TABLE " + CATEGORIES_NAME + " (" + //$NON-NLS-1$ //$NON-NLS-2$
				CATEGORIES_FILTER_ID + ", " + CATEGORIES_COL_CATEGORY + ", " + CATEGORIES_COL_SUBCATEGORY + ");"; //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
    private OsmandApplication context;
    private SQLiteConnection conn;
    private MapPoiTypes mapPoiTypes;
    
    PoiFilterDbHelper(MapPoiTypes mapPoiTypes, OsmandApplication context) {
        this.mapPoiTypes = mapPoiTypes;
        this.context = context;
    }
    
    public SQLiteConnection getWritableDatabase() {
        return openConnection(false);
    }
    
    public void close() {
        if (conn != null) {
            conn.close();
            conn = null;
        }
    }
    
    public SQLiteConnection getReadableDatabase() {
        return openConnection(true);
    }
    
    private SQLiteConnection openConnection(boolean readonly) {
        conn = context.getSQLiteAPI().getOrCreateDatabase(DATABASE_NAME, readonly);
        if (conn.getVersion() == 0 || DATABASE_VERSION != conn.getVersion()) {
            if (readonly) {
                conn.close();
                conn = context.getSQLiteAPI().getOrCreateDatabase(DATABASE_NAME, readonly);
            }
            if (conn.getVersion() == 0) {
                conn.setVersion(DATABASE_VERSION);
                onCreate(conn);
            } else {
                onUpgrade(conn, conn.getVersion(), DATABASE_VERSION);
            }
            
        }
        return conn;
    }
    
    public void onCreate(SQLiteConnection conn) {
        conn.execSQL(FILTER_TABLE_CREATE);
        conn.execSQL(CATEGORIES_TABLE_CREATE);
    }
    
    
    public void onUpgrade(SQLiteConnection conn, int oldVersion, int newVersion) {
        if (newVersion <= 5) {
            deleteOldFilters(conn);
        }
        conn.setVersion(newVersion);
    }
    
    private void deleteOldFilters(SQLiteConnection conn) {
        for (NSString * toDel : DEL) {
            deleteFilter(conn, "user_" + toDel);
        }
    }
    
    protected boolean addFilter(OAPOIUIFilter * p, SQLiteConnection db, boolean addOnlyCategories) {
        if (db != null) {
            if (!addOnlyCategories) {
                db.execSQL("INSERT INTO " + FILTER_NAME + " VALUES (?, ?, ?)", new Object[]{p.getName(), p.getFilterId(), p.getFilterByName()}); //$NON-NLS-1$ //$NON-NLS-2$
            }
            Map<PoiCategory, LinkedHashSet<NSString *>> types = p.getAcceptedTypes();
            SQLiteStatement insertCategories = db.compileStatement("INSERT INTO " + CATEGORIES_NAME + " VALUES (?, ?, ?)"); //$NON-NLS-1$ //$NON-NLS-2$
            for (PoiCategory a : types.keySet()) {
                if (types.get(a) == null) {
                    insertCategories.bindString(1, p.getFilterId());
                    insertCategories.bindString(2, a.getKeyName());
                    insertCategories.bindNull(3);
                    insertCategories.execute();
                } else {
                    for (NSString * s : types.get(a)) {
                        insertCategories.bindString(1, p.getFilterId());
                        insertCategories.bindString(2, a.getKeyName());
                        insertCategories.bindString(3, s);
                        insertCategories.execute();
                    }
                }
            }
            insertCategories.close();
            return true;
        }
        return false;
    }
    
    protected List<OAPOIUIFilter *> getFilters(SQLiteConnection conn) {
        ArrayList<OAPOIUIFilter *> list = new ArrayList<OAPOIUIFilter *>();
        if (conn != null) {
            SQLiteCursor query = conn.rawQuery("SELECT " + CATEGORIES_FILTER_ID + ", " + CATEGORIES_COL_CATEGORY + "," + CATEGORIES_COL_SUBCATEGORY + " FROM " +  //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$ //$NON-NLS-4$
                                               CATEGORIES_NAME, null);
            Map<NSString *, Map<PoiCategory, LinkedHashSet<NSString *>>> map = new LinkedHashMap<NSString *, Map<PoiCategory, LinkedHashSet<NSString *>>>();
            if (query.moveToFirst()) {
                do {
                    NSString * filterId = query.getString(0);
                    if (!map.containsKey(filterId)) {
                        map.put(filterId, new LinkedHashMap<PoiCategory, LinkedHashSet<NSString *>>());
                    }
                    Map<PoiCategory, LinkedHashSet<NSString *>> m = map.get(filterId);
                    PoiCategory a = mapPoiTypes.getPoiCategoryByName(query.getString(1).toLowerCase(), false);
                    NSString * subCategory = query.getString(2);
                    if (subCategory == null) {
                        m.put(a, null);
                    } else {
                        if (m.get(a) == null) {
                            m.put(a, new LinkedHashSet<NSString *>());
                        }
                        m.get(a).add(subCategory);
                    }
                } while (query.moveToNext());
            }
            query.close();
            
            query = conn.rawQuery("SELECT " + FILTER_COL_ID + ", " + FILTER_COL_NAME + "," + FILTER_COL_FILTERBYNAME + " FROM " +  //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$ //$NON-NLS-4$
                                  FILTER_NAME, null);
            if (query.moveToFirst()) {
                do {
                    NSString * filterId = query.getString(0);
                    if (map.containsKey(filterId)) {
                        OAPOIUIFilter * filter = new OAPOIUIFilter *(query.getString(1), filterId,
                                                                     map.get(filterId), application);
                        filter.setSavedFilterByName(query.getString(2));
                        list.add(filter);
                    }
                } while (query.moveToNext());
            }
            query.close();
        }
        return list;
    }
    
    protected boolean editFilter(SQLiteConnection conn, OAPOIUIFilter * filter) {
        if (conn != null) {
            conn.execSQL("DELETE FROM " + CATEGORIES_NAME + " WHERE " + CATEGORIES_FILTER_ID + " = ?",  //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
                         new Object[]{filter.getFilterId()});
            addFilter(filter, conn, true);
            updateName(conn, filter);
            return true;
        }
        return false;
    }
    
    private void updateName(SQLiteConnection db, OAPOIUIFilter * filter) {
        db.execSQL("UPDATE " + FILTER_NAME + " SET " + FILTER_COL_FILTERBYNAME + " = ?, " + FILTER_COL_NAME + " = ? " + " WHERE " //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$ //$NON-NLS-4$ //$NON-NLS-5$
                   + FILTER_COL_ID + "= ?", new Object[]{filter.getFilterByName(), filter.getName(), filter.getFilterId()}); //$NON-NLS-1$
    }
    
    protected boolean deleteFilter(SQLiteConnection db, OAPOIUIFilter * p) {
        NSString * key = p.getFilterId();
        return deleteFilter(db, key);
    }
    
    private boolean deleteFilter(SQLiteConnection db, NSString * key) {
        if (db != null) {
            db.execSQL("DELETE FROM " + FILTER_NAME + " WHERE " + FILTER_COL_ID + " = ?", new Object[]{key}); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            db.execSQL(
                       "DELETE FROM " + CATEGORIES_NAME + " WHERE " + CATEGORIES_FILTER_ID + " = ?", new Object[]{key}); //$NON-NLS-1$ //$NON-NLS-2$ //$NON-NLS-3$
            return true;
        }
        return false;
    }
    
    
}

@end
