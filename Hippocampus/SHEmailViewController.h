//
//  SHEmailViewController.h
//  Hippocampus
//
//  Created by Will Schreiber on 10/13/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SHEmailViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property (strong, nonatomic) NSString* emailHTML;

@end
