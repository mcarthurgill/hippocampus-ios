//
//  HCBucketDetailsViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 2/18/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

#define PICTURE_HEIGHT 180
#define PICTURE_MARGIN_TOP 4

@protocol HCUpdateBucketDelegate <NSObject>
-(void)updateBucket:(NSMutableDictionary *)updatedBucket;
@end

@interface HCBucketDetailsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
{
    BOOL unsavedChanges;
    BOOL savingChanges;
    MBProgressHUD* hud;
}

@property (nonatomic,assign) id delegate;

@property (strong, nonatomic) NSMutableDictionary* bucket;
@property (strong, nonatomic) NSMutableArray* sections;
@property (strong, nonatomic) NSMutableArray* actionCells;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSString *updatedBucketName;

@end
