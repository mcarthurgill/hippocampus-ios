//
//  LXMediumObject.h
//  Hippocampus
//
//  Created by Will Schreiber on 11/25/15.
//  Copyright © 2015 LXV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NYTPhoto.h"

@interface LXMediumObject : NSObject <NYTPhoto>

- (id) initWithMutableDictionary:(NSMutableDictionary*)md;

@property (strong, nonatomic) NSMutableDictionary* mutableDictionary;

@end
