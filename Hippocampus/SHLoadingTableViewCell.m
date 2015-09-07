//
//  SHLoadingTableViewCell.m
//  Hippocampus
//
//  Created by Will Schreiber on 8/24/15.
//  Copyright (c) 2015 LXV. All rights reserved.
//

#import "SHLoadingTableViewCell.h"
#import "SHSlackThoughtsViewController.h"

@implementation SHLoadingTableViewCell

@synthesize responseObject;

- (void)awakeFromNib
{
    // Initialization code
    inverted = NO;
    
    if (!inverted) {
        self.transform = CGAffineTransformMake(1, 0, 0, -1, 0, 0);
        inverted = YES;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshedObject:) name:@"refreshedObject" object:nil];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) configureWithResponseObject:(NSMutableDictionary*)rO
{
    //NSLog(@"height: %f", self.frame.size.height);
    //NSLog(@"rO: %@", rO);
    [self setResponseObject:rO];
}


- (void) refreshedObject:(NSNotification*)notification
{
    //NSLog(@"%@|%@|", [[notification userInfo] objectForKey:@"local_key"], [self.responseObject localKey]);
    if ([[notification userInfo] objectForKey:@"local_key"] && [self.responseObject localKey] && [[[notification userInfo] objectForKey:@"local_key"] isEqualToString:[self.responseObject localKey]]) {
        //this is a hit, a currently displaying talbeivewcell. reload it.
        if ([[self.responseObject objectForKey:@"vc"] respondsToSelector:@selector(tryToReload)]) {
            [(SHSlackThoughtsViewController*)[self.responseObject objectForKey:@"vc"] tryToReload];
        }
    }
}



- (UITableView *)relatedTable
{
    if ([self.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview;
    else if ([self.superview.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview.superview;
    else if ([self.superview.superview.superview isKindOfClass:[UITableView class]])
        return (UITableView *)self.superview.superview.superview;
    else
        return nil;
}

@end
