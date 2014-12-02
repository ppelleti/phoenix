//
//  main.m
//  phoenix
//
//  Created by Gregory Casamento on 10/29/14.
//  Copyright (c) 2014 indie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Lexer.h"
#import "AST.h"
// #import "bridge.h"

// ASTNode* bridge_yyparse(Lexer * lexer, int debug);
// const char * bridge_yyerror();

NSDictionary *swiftCompiler(NSString *sourceCode, BOOL debug)
{
    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    Lexer *lexer = [[Lexer alloc] initWithSourceCode:sourceCode];
    if(debug)
    {
        NSLog(@"Lexer Tokens");
        NSLog(@"============");
        [lexer debugTokens];
        NSLog(@"============\n");
        

        NSLog(@"AST Parser");
        NSLog(@"===========");
    }
    
    foo();
    
    ASTNode *ast = bridge_yyparse(lexer, debug);
    if(ast != nil)
    {
        NSString *program = [ast toCode];
        NSString *error = [NSString stringWithUTF8String:bridge_yyerror()];
        [result setObject:program forKey:@"program"];
        [result setObject:error forKey:@"error"];
    }
    
    return result;
}


int main(int argc, const char * argv[]) {
    @autoreleasepool {
        // insert code here...
        BOOL debug = NO;
        
        /*
        if(argc <= 1)
        {
            puts("No input files");
            return 0;
        }
         */
        
        NSString *fileName = @"/tmp/test1.swift";
        // NSString *fileName = [NSString stringWithUTF8String:argv[1]];
        NSString *sourceCode = [NSString stringWithContentsOfFile:fileName
                                                         encoding:NSUTF8StringEncoding
                                                            error:NULL];
        
        NSDictionary *result = swiftCompiler(sourceCode, debug);
        
        NSString *outputCode = [result objectForKey:@"program"];
        NSString *error = [result objectForKey:@"error"];
        
        NSLog(@"Code Output: %@",outputCode);
        NSLog(@"Errors: %@",error);

    }
    return 0;
}
