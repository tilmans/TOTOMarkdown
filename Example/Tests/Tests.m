//
//  TOTOMarkdownTests.m
//  TOTOMarkdownTests
//
//  Created by Tilman Schlenker on 12/14/2014.
//  Copyright (c) 2014 Tilman Schlenker. All rights reserved.
//

#import <TOTOMarkdown/TOTOMarkdownParser.h>

SpecBegin(InitialSpecs)

describe(@"test simple conversion", ^{

    TOTOMarkdownParser* p = [TOTOMarkdownParser new];
    
    it(@"can convert italic", ^{
        p.markdown = @"*italic*";
        NSString* md = [p parseMarkdown].string;
        expect(md).to.equal(@"italic");
    });

});

SpecEnd
