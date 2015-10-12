//
//  SHPaywallViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 9/30/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHPaywallViewController.h"

@interface SHPaywallViewController ()

@end

@implementation SHPaywallViewController

@synthesize productIDs;
@synthesize productsArray;

@synthesize titleImage;
@synthesize messageLabel;
@synthesize actionButton;
@synthesize secondaryActionButton;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupAppearance];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
    [[[LXSession thisSession] user] updateTimeZone]; //this is a hack just to refresh the user object and make sure the user isn't marked as subscribed server-side
    
    self.productIDs = [[NSMutableArray alloc] init];
    [self.productIDs addObject:@"1month"];
    self.productsArray = [[NSMutableArray alloc] init];
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    [self requestProductInfo];
}

- (void) setupAppearance
{
    [self.titleImage setImage:[UIImage imageNamed:@"60x60.png"]];
    
    [self.messageLabel setFont:[UIFont titleFontWithSize:18.0f]];
    [self.messageLabel setTextColor:[UIColor SHFontDarkGray]];
    
    [self.messageLabel setText:@"Hey there.\n\nWe initially built Hippo to remember details about investors we were meeting, although over the past two years Hippo has changed our lives.\n\nHippo has become an assistant for our brains. It helps us advance our careers, improve our relationships, and close more deals.\n\nHippo is so important to us that we'll never raise money for it, never sell it, never sell your data, never stop working on it and never shut it down.\n\nSet a nudge for 50 years from now and you will receive it.\n\nHippo is $4.99/month. For the price of a cup of coffee, you can remember those tiny details about people that make all the difference.\n\nWe believe Hippo will change your life. If it doesn’t, we'll give your money back.\n\nWith love,\nMcArthur Gill + Will Schreiber"];
    
    [self.actionButton.layer setCornerRadius:4.0f];
    [self.actionButton setClipsToBounds:YES];
    [[self.actionButton titleLabel] setFont:[UIFont titleFontWithSize:16.0f]];
    [self.actionButton setBackgroundColor:[UIColor SHColorBlue]];
    [self.actionButton setTintColor:[UIColor whiteColor]];
    [self.actionButton setTitle:@"$4.99/month" forState:UIControlStateNormal];
    
    [[self.secondaryActionButton titleLabel] setFont:[UIFont secondaryFontWithSize:13.0f]];
    [self.secondaryActionButton setTintColor:[UIColor SHFontDarkGray]];
    [self.secondaryActionButton setTitle:@"I'm already a paying user >" forState:UIControlStateNormal];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO];
}

- (void) refreshedObject:(NSNotification*)notification
{
    NSLog(@"refreshedObject on paywall: %@", [notification userInfo]);
    if ([[notification userInfo] objectForKey:@"object_type"] && [[[notification userInfo] objectForKey:@"object_type"] isEqualToString:@"user"]) {
        if ([[[LXSession thisSession] user] hasMembership]) {
            [self dismissView];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




# pragma mark payment delegate

- (void) requestProductInfo
{
    if ([SKPaymentQueue canMakePayments]) {
        NSSet* productIdentifiers = [[NSSet alloc] initWithArray:self.productIDs];
        SKProductsRequest* productRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];
        
        [productRequest setDelegate:self];
        [productRequest start];
    } else {
        NSLog(@"can't make payments!");
    }
}

- (void) productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{
    if (response.products.count != 0) {
        for (SKProduct* product in response.products) {
            [self.productsArray addObject:product];
            
            NSLog(@"product: %@, %@", [product localizedTitle], [product localizedDescription]);
        }
        NSLog(@"productsArray: %@", self.productsArray);
    } else {
        NSLog(@"no products!");
    }
    if (response.invalidProductIdentifiers.count > 0) {
        NSLog(@"invalid products: %@", response.invalidProductIdentifiers);
    }
}

- (void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions
{
    for (SKPaymentTransaction* transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
            {
                NSLog(@"PURCHASED!");
                [[[LXSession thisSession] user] updateToMembership:@"standard"
                                                           success:^(id responseObject) {
                                                               NSLog(@"successful update!");
                                                               [self hideHUD];
                                                               [self dismissView];
                                                           }
                                                           failure:^(NSError* error) {
                                                               [self hideHUD];
                                                               NSLog(@"error updating user");
                                                           }
                 ];
                break;
            }
            case SKPaymentTransactionStateRestored:
            {
                NSLog(@"RESTORED!");
                [[[LXSession thisSession] user] updateToMembership:@"standard"
                                                           success:^(id responseObject) {
                                                               NSLog(@"successful update!");
                                                               [self hideHUD];
                                                               [self dismissView];
                                                           }
                                                           failure:^(NSError* error) {
                                                               [self hideHUD];
                                                               NSLog(@"error updating user");
                                                           }
                 ];
                break;
            }
            case SKPaymentTransactionStateFailed:
                NSLog(@"FAILED!");
                NSLog(@"error: %@", transaction.error.localizedDescription);
                [self hideHUD];
                break;
            default:
                NSLog(@"rawValue: %ld", (long)transaction.transactionState);
                break;
        }
    }
}

- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self hideHUD];
    NSLog(@"completed restore");
}

- (void) paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    [self hideHUD];
    NSLog(@"payment queue restore failed: %@", error.localizedDescription);
}


# pragma mark helper actions

- (void) dismissView
{
    [self.navigationController popToRootViewControllerAnimated:NO];
}


# pragma mark actions

- (IBAction)action:(id)sender
{
    if ([self.productsArray count] > 0) {
        [self showHUDWithMessage:@"Loading"];
        [[SKPaymentQueue defaultQueue] addPayment:[SKPayment paymentWithProduct:[self.productsArray firstObject]]];
    }
}

- (IBAction)secondaryAction:(id)sender
{
    [self showHUDWithMessage:@"Restoring"];
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}



# pragma mark status bar

- (BOOL) prefersStatusBarHidden
{
    return YES;
}



# pragma mark hud delegate

- (void) showHUDWithMessage:(NSString*) message
{
    hud = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:hud];
    hud.labelText = message;
    hud.color = [[UIColor SHGreen] colorWithAlphaComponent:0.8f];
    [hud show:YES];
}

- (void) hideHUD
{
    if (hud) {
        [hud hide:YES];
    }
}



@end
