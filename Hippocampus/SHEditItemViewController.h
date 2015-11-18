//
//  SHEditItemViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/11/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHEditItemViewController : UIViewController <UITextViewDelegate>

@property (strong, nonatomic) NSString* localKey;

@property (strong, nonatomic) IBOutlet UITextView *textView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *bottomMargin;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *topMargin;

@end
