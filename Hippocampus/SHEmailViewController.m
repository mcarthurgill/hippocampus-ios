//
//  SHEmailViewController.m
//  Hippocampus
//
//  Created by Will Schreiber on 10/13/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import "SHEmailViewController.h"

@interface SHEmailViewController ()

@end

@implementation SHEmailViewController

@synthesize webView;
@synthesize emailHTML;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSString stringWithFormat:@"<html><head><meta name='viewport' content='width=device-width'>></head><body>%@</body></html>", self.emailHTML];
    [self.webView loadHTMLString:self.emailHTML baseURL:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

@end
