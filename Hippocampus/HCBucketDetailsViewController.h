//
//  HCBucketDetailsViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HCUpdateBucketDelegate <NSObject>
-(void)updateBucket:(NSMutableDictionary *)updatedBucket;
@end

@interface HCBucketDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>
{
    BOOL unsavedChanges;
    BOOL savingChanges;
}

@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSString *updatedBucketName;
@property (nonatomic,assign) id delegate;

@end
