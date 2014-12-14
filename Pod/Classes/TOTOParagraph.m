//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import "TOTOParagraph.h"

@implementation TOTOParagraph
-(NSString*)indentTabs
{
    NSMutableString* string = [NSMutableString string];
    for (int it=0; it<self.indent; it++) {
        [string appendString:@"\t"];
    }
    return string;
}
@end
