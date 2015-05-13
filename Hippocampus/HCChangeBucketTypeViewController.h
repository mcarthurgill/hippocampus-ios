//
//  HCChangeBucketTypeViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HCUpdateBucketTypeDelegate <NSObject>
- (void) updateBucketGroup:(NSMutableDictionary *)updatedBucket;
@end

@interface HCChangeBucketTypeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSMutableArray* typeOptions;
@property (strong, nonatomic) IBOutlet UIPickerView *pickerView;
@property (strong, nonatomic) NSMutableDictionary *bucketDict;
@property (strong, nonatomic) NSDictionary *selectedBucketType;
@property (strong, nonatomic) NSDictionary *selectedGroup;

@property (nonatomic,assign) id delegate;
@property (strong, nonatomic) IBOutlet UITextField *groupField;
@property (strong, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
