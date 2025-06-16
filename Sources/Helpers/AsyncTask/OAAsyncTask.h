//
//  OAAsyncTask.h
//  OsmAnd
//
//  Created by Max Kojin on 13/06/25.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

@interface OAAsyncTask: NSObject

- (void) execute;
- (void) onPreExecute;
- (id) doInBackground;
- (void) onPostExecute:(id)result;

@end
