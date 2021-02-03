//
//  OALoadGpxTask.m
//  OsmAnd
//
//  Created by Anna Bibyk on 31.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OALoadGpxTask.h"
#import "OAGpxInfo.h"
#import "OsmAndApp.h"

//public static final String GPX_INDEX_DIR = "tracks/";
//public static final String GPX_RECORDED_INDEX_DIR = GPX_INDEX_DIR + "rec/";
//public static final String GPX_IMPORT_DIR = GPX_INDEX_DIR + "import/";

@implementation OALoadGpxTask
{
    NSArray <OAGpxInfo *> *_result;
}

/*
protected List<GpxInfo> doInBackground(Activity... params) {
    List<GpxInfo> result = new ArrayList<>();
    loadGPXData(app.getAppPath(IndexConstants.GPX_INDEX_DIR), result, this);
    return result;
}
*/

- (NSArray <OAGpxInfo *> *) doInBackground
{
    NSArray *result = [NSArray array];
    [self loadGPXData:OsmAndApp.instance.gpxPath result:result loadTask:self];
    return result;
}

/*
public void loadFile(GpxInfo... loaded) {
    publishProgress(loaded);
}
 */
 
- (void) loadFile
{
    
}

- (void) execute:(void(^)(NSArray <OAGpxInfo *>*))onComplete
{
    [self onPreExecute];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doInBackground];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onPostExecute:onComplete];
        });
    });
}

/*
@Override
protected void onPreExecute() {
    showProgressBar();
    listView.setEmptyView(null);
    allGpxAdapter.clear();
}
 */

- (void) onPreExecute
{
    
}
 
 /*
@Override
protected void onProgressUpdate(GpxInfo... values) {
    for (GpxInfo v : values) {
        allGpxAdapter.addLocalIndexInfo(v);
    }
    allGpxAdapter.notifyDataSetChanged();
}
 */

- (void) onProgressUpdate
{
    
}
  
 /*
@Override
protected void onPostExecute(List<GpxInfo> result) {
    this.result = result;
    allGpxAdapter.refreshSelected();
    hideProgressBar();
    listView.setEmptyView(emptyView);
    if (allGpxAdapter.getGroupCount() > 0 &&
        allGpxAdapter.isShowingSelection()) {
        getExpandableListView().expandGroup(0);
    }
}
 */

- (void) onPostExecute:(void(^)(NSArray <OAGpxInfo *>*))onComplete
{
    if (onComplete)
        onComplete(_result);
}


 
 /*
private File[] listFilesSorted(File dir) {
    File[] listFiles = dir.listFiles();
    if (listFiles == null) {
        return new File[0];
    }
    // This file could be sorted in different way for folders
    // now folders are also sorted by last modified date
    final Collator collator = OsmAndCollator.primaryCollator();
    Arrays.sort(listFiles, new Comparator<File>() {
        @Override
        public int compare(File f1, File f2) {
            if (sortByMode == TracksSortByMode.BY_NAME_ASCENDING) {
                return collator.compare(f1.getName(), (f2.getName()));
            } else if (sortByMode == TracksSortByMode.BY_NAME_DESCENDING) {
                return -collator.compare(f1.getName(), (f2.getName()));
            } else {
                // here we could guess date from file name '2017-08-30 ...' - first part date
                if (f1.lastModified() == f2.lastModified()) {
                    return -collator.compare(f1.getName(), (f2.getName()));
                }
                return -((f1.lastModified() < f2.lastModified()) ? -1 : ((f1.lastModified() == f2.lastModified()) ? 0 : 1));
            }
        }
    });
    return listFiles;
}
 */

- (NSArray <NSString *> *) listFilesSorted:(NSString *)dir
{
    
}
 
 /*
private void loadGPXData(File mapPath, List<GpxInfo> result, LoadGpxTask loadTask) {
    if (mapPath.canRead()) {
        List<GpxInfo> progress = new ArrayList<>();
        loadGPXFolder(mapPath, result, loadTask, progress, "");
        if (!progress.isEmpty()) {
            loadTask.loadFile(progress.toArray(new GpxInfo[0]));
        }
    }
}
 */

- (void) loadGPXData:(NSString *) mapPath result:(NSArray <OAGpxInfo *> *)result loadTask:(OALoadGpxTask *)loadTask
{
    NSMutableArray *progress = [NSMutableArray array];
    [self loadGPXFolder:mapPath result:result loadTask:loadTask progress:progress gpxSubfolder:@""];
    if (progress.count > 0)
    {
        
    }
}

- (void) getAllFolders
{
    NSMutableDictionary *folders = [NSMutableDictionary dictionary];
    NSArray* dirs = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:OsmAndApp.instance.gpxPath error:Nil];
    NSMutableArray* tracksFolder = [NSMutableArray array];
    
    for (NSString *item in dirs)
    {
        NSMutableArray *folderContent = [NSMutableArray array];
        if (![[item pathExtension] isEqual:@"gpx"])
        {
            NSString *path = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:item];
            NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:Nil];
            if (array)
            {
                for (NSString *track in array)
                {
                    OAGPX *gpx = [OAGPXDatabase.sharedDb getGPXItem:track];
                    OAGpxInfo *gpxInfo = [[OAGpxInfo alloc] initWithGpx:gpx name:track];
                    gpxInfo.subfolder = item;
                    gpxInfo.file = [path stringByAppendingPathComponent:track];
                    if ([item isEqualToString:@"tracks"])
                        [tracksFolder addObject:gpxInfo];
                    else
                        [folderContent addObject:gpxInfo];
                }
                [folders setObject:folderContent forKey:item];
            }
        }
        else
        {
            OAGPX *gpx = [OAGPXDatabase.sharedDb getGPXItem:item];
            OAGpxInfo *gpxInfo = [[OAGpxInfo alloc] initWithGpx:gpx name:item];
            gpxInfo.subfolder = @"tracks";
            gpxInfo.file = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:item];
            [tracksFolder addObject:gpxInfo];
        }
    }
    if (tracksFolder.count > 0)
        [folders setObject:tracksFolder forKey:@"tracks"];
    //_gpxFolders = [NSMutableDictionary dictionaryWithDictionary:folders];
}
 
 /*
private void loadGPXFolder(File mapPath, List<GpxInfo> result, LoadGpxTask loadTask, List<GpxInfo> progress,
                           String gpxSubfolder) {
    File[] listFiles = listFilesSorted(mapPath);
    for (File gpxFile : listFiles) {
        if (gpxFile.isDirectory()) {
            String sub = gpxSubfolder.length() == 0 ? gpxFile.getName() : gpxSubfolder + "/"
            + gpxFile.getName();
            loadGPXFolder(gpxFile, result, loadTask, progress, sub);
        } else if (gpxFile.isFile() && gpxFile.getName().toLowerCase().endsWith(IndexConstants.GPX_FILE_EXT)) {
            GpxInfo info = new GpxInfo();
            info.subfolder = gpxSubfolder;
            info.file = gpxFile;
            result.add(info);
            progress.add(info);
            if (progress.size() > 7) {
                loadTask.loadFile(progress.toArray(new GpxInfo[0]));
                progress.clear();
            }
        }
    }
}
 */

- (void) loadGPXFolder:(NSString *) mapPath result:(NSArray <OAGpxInfo *> *)result loadTask:(OALoadGpxTask *)loadTask progress:(NSArray <OAGpxInfo *>*)progress gpxSubfolder:(NSString *)gpxSubfolder
{
  
    
}
 
 /*
public List<GpxInfo> getResult() {
    return result;
}
}
*/

- (NSArray <OAGpxInfo *> *) getResult
{
    return _result;
}

@end
