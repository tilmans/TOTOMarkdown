//
//  Copyright (c) 2014 Tilman Schlenkr. All rights reserved.
//

#import "TOTOLine.h"

@implementation TOTOLine {
    NSString* _line;
}

- (instancetype)initWithLine:(NSString*)line
{
    self = [super init];
    if (self) {
        _line = line;
        [self setTypeAndGroup];
    }
    return self;
}

-(void)setTypeAndGroup
{
    NSRange range = NSMakeRange(0, _line.length);
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*#\\s*([^#]*)$"
                                                                           options:0 error:nil];
    NSTextCheckingResult* match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Header1;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*=+\\s*$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Header1Before;
        _text = @"";
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*##\\s*([^#]*)$"
                                                                           options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Header2;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*###\\s*([^#]*)$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Header3;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*####\\s*([^#]*)$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Header4;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*--\\s*$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = HR;
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\s*)[\\*|\\-]\\s(.*)$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = List;
        _indent = [_line substringWithRange:[match rangeAtIndex:1]].length;
        _text = [_line substringWithRange:[match rangeAtIndex:2]];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"(^\\s{4}.*$)"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Code;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        _text = [_text stringByReplacingOccurrencesOfString:@"*" withString:@"\\*"];
        _text = [_text stringByReplacingOccurrencesOfString:@"_" withString:@"\\_"];
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Empty;
        _text = @"";
        return;
    }

    regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(\\S+.*)\\s*$"
                                                      options:0 error:nil];
    match = [regex firstMatchInString:_line options:0 range:range];
    if (match.numberOfRanges > 0) {
        _type = Regular;
        _text = [_line substringWithRange:[match rangeAtIndex:1]];
        return;
    }

    _type = Unknown;
    _text = @"";
}

-(BOOL)line:(NSString*)line matchesRegex:(NSString*)regex
{
    NSRegularExpression* cReg = [NSRegularExpression regularExpressionWithPattern:regex
                                                                          options:0 error:nil];
    if ([cReg matchesInString:line options:0 range:NSMakeRange(0, line.length)]) {
        return YES;
    }
    return NO;
}
@end
