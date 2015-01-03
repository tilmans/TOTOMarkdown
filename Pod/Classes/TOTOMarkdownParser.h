//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TOTOMarkdownParser : NSObject
@property (nonatomic, strong) UIColor* textColor;
@property (nonatomic, assign) CGFloat hrWidth;
@property (nonatomic, strong) NSString* markdown;

-(NSAttributedString*)parseMarkdown;
@end
