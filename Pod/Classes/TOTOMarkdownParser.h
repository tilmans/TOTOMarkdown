//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TOTOMarkdownParser : NSObject
@property (nonatomic, strong) UIColor* textColor;
@property (nonatomic, strong) NSString* markdown;
@property (nonatomic) BOOL blackHR;

-(NSAttributedString*)parseMarkdown;
@end
