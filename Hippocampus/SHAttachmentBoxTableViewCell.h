//
//  SHAttachmentBoxTableViewCell.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/9/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHAttachmentBoxTableViewCell : UITableViewCell

@property (strong, nonatomic) id delegate;

@property (strong, nonatomic) NSString* localKey;
@property (strong, nonatomic) NSMutableDictionary* attachment;
@property (strong, nonatomic) NSString* attachmentType;

@property (strong, nonatomic) UILongPressGestureRecognizer* longPress;

@property (strong, nonatomic) IBOutlet UIView *card;
@property (strong, nonatomic) IBOutlet UIImageView *leftImageView;
@property (strong, nonatomic) IBOutlet UIView *separatorView;

@property (strong, nonatomic) IBOutlet UILabel *topLabel;
@property (strong, nonatomic) IBOutlet UILabel *centerLabel;
@property (strong, nonatomic) IBOutlet UILabel *bottomLabel;
@property (strong, nonatomic) IBOutlet UILabel *rightLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *centerLabelHeight;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *verticalSpaceBetweenLabels;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftAlignmentForBottomLabel;

- (void) configureWithLocalKey:(NSString*)key attachment:(NSMutableDictionary*)attchmnt type:(NSString*)type;

@end
