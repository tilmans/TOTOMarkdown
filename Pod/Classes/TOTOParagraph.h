//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum LineType : NSUInteger {
    Regular,
    Header1,
    Header1Before,
    Header2,
    Header2Before,
    Header3,
    Header4,
    Header5,
    Header6,
    UnorderedList,
    OrderedList,
    Code,
    Quote,
    HR,
    Empty,
    Unknown
} LineType;

@interface TOTOParagraph : NSObject
@property (nonatomic) LineType type;
@property (nonatomic, strong) NSString* text;
@property (nonatomic) NSUInteger indent;
@property (nonatomic, readonly) NSString* indentTabs;
@end
