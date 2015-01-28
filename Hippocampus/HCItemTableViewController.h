//
//  HCItemTableViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 7/8/14.
//  Copyright (c) 2014 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HCItemTableViewController : UITableViewController <UITextViewDelegate>
{
    BOOL unsavedChanges;
    BOOL savingChanges;
    
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSMutableDictionary* item;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *saveButton;
@property (strong, nonatomic) NSMutableArray* sections;

@property (strong, nonatomic) NSMutableDictionary* mediaDictionary;

- (IBAction)saveAction:(id)sender;

- (void) saveReminder:(NSString*)reminder withType:(NSString*)type;
- (void) saveUpdatedMessage:(NSString *)updatedMessage;
- (void) addToStack:(id)stackID;

@end
