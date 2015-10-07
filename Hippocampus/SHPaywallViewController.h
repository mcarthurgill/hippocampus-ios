//
//  SHPaywallViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 9/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>
@import StoreKit;

@interface SHPaywallViewController : UIViewController <SKProductsRequestDelegate, SKPaymentTransactionObserver>
{
    MBProgressHUD* hud;
}

@property (strong, nonatomic) NSMutableArray* productIDs;
@property (strong, nonatomic) NSMutableArray* productsArray;

@property (strong, nonatomic) IBOutlet UIImageView *titleImage;
@property (strong, nonatomic) IBOutlet UILabel *messageLabel;
@property (strong, nonatomic) IBOutlet UIButton *actionButton;
@property (strong, nonatomic) IBOutlet UIButton *secondaryActionButton;

- (IBAction)action:(id)sender;
- (IBAction)secondaryAction:(id)sender;

@end
