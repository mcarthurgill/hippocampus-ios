//
//  HCChangeBucketTypeViewController.h
//  Hippocampus
//
//  Created by Joseph McArthur Gill on 4/1/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HCUpdateBucketTypeDelegate <NSObject>
-(void)updateBucketType:(NSMutableDictionary *)updatedBucket;
@end

@interface HCChangeBucketTypeViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) NSMutableArray* typeOptions;
@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;
@property (weak, nonatomic) NSMutableDictionary *bucketDict;
@property (weak, nonatomic) NSDictionary *selectedBucketType;
@property (nonatomic,assign) id delegate;

- (IBAction)saveAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@end
