

- (void)startDownloadOf:(BaseDownloadItem*)item
{
    // Create download tasks
    NSURLRequest* request = [NSURLRequest requestWithURL:item.resourceInRepository->url.toNSURL()];
    id<OADownloadTask> task = [_app.downloadsManager downloadTaskWithRequest:request
                                                                      andKey:[@"resource:" stringByAppendingString:item.resourceInRepository->id.toNSString()]];
    [self obtainDownloadItems];

    // Reload this item in the table
    NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if (![obj isKindOfClass:[DownloadedItem class]])
            return NO;

        DownloadedItem* downloaded = (DownloadedItem*)obj;
        if (downloaded.downloadTask != task)
            return NO;

        *stop = YES;
        return YES;
    }];
    NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                    inSection:_downloadsSection];
    [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:itemIndexPath]
                      withRowAnimation:UITableViewRowAnimationAutomatic];

    // Resume task finally
    [task resume];
}

- (void)cancelDownloadOf:(BaseDownloadItem*)item
{
    DownloadedItem* downloadedItem = (DownloadedItem*)item;

    [downloadedItem.downloadTask cancel];
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSNumber* progressCompleted = (NSNumber*)value;

    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;

        NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
            if (![obj isKindOfClass:[DownloadedItem class]])
                return NO;

            DownloadedItem* downloadedItem = (DownloadedItem*)obj;
            if (downloadedItem.downloadTask != task)
                return NO;

            *stop = YES;
            return YES;
        }];
        NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                        inSection:_downloadsSection];
        UITableViewCell* itemCell = [_tableView cellForRowAtIndexPath:itemIndexPath];
        FFCircularProgressView* progressView = (FFCircularProgressView*)itemCell.accessoryView;

        [progressView stopSpinProgressBackgroundLayer];
        progressView.progress = [progressCompleted floatValue];
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    NSString* localPath = task.targetPath;

    BOOL needsManualRowReload = YES;

    if (localPath != nil && task.state == OADownloadTaskStateFinished)
    {
        const auto& filePath = QString::fromNSString(localPath);
        bool ok = false;

        // Try to install only in case of successful download
        if (task.error == nil)
        {
            // Install or update given resource
            const auto& resourceId = QString::fromNSString([task.key substringFromIndex:[@"resource:" length]]);
            ok = _app.resourcesManager->updateFromFile(resourceId, filePath);
            if (!ok)
                ok = _app.resourcesManager->installFromRepository(resourceId, filePath);
        }

        [[NSFileManager defaultManager] removeItemAtPath:task.targetPath error:nil];

        needsManualRowReload = !ok;
    }

    if (needsManualRowReload)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isViewLoaded)
                return;

            [self obtainDownloadItems];

            NSUInteger downloadItemIndex = [_downloadItems indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
                if (![obj isKindOfClass:[DownloadedItem class]])
                    return NO;

                DownloadedItem* downloadedItem = (DownloadedItem*)obj;
                if (downloadedItem.downloadTask != task)
                    return NO;

                *stop = YES;
                return YES;
            }];
            NSIndexPath* itemIndexPath = [NSIndexPath indexPathForRow:downloadItemIndex
                                                            inSection:_downloadsSection];

            [_tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:itemIndexPath]
                              withRowAnimation:UITableViewRowAnimationAutomatic];
        });
    }
}


@end
