//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TOTOParagraph.h"

@interface TOTOLine : NSObject
@property (nonatomic, readonly) LineType type;
@property (nonatomic, readonly) NSString* text;
@property (readonly) NSUInteger indent;

- (instancetype)initWithLine:(NSString*)line;
@end
