#import "AST.h"

@implementation StatementsNode

@synthesize current;

- (id) initWithCurrent: (ASTNode *)acurrent
{
    self = [super init];
    if(self)
    {
        self.current = acurrent;
    }
    return self;
}

- (id) initWithCurrent: (ASTNode *)acurrent
                  next: (StatementsNode *)anext
{
    self = [super init];
    if(self)
    {
        self.current = acurrent;
        self.next = anext;
    }
    return self;
}

- (NSString *)toCode
{
    if (self.firstStatement)
    {
        [ctx saveSymbols];
    }
    
    NSString *result = @"";
    ASTNode *currentStatement = self.current;
    if (currentStatement)
    {
        [ctx saveExported];
        NSString *tmp = [[currentStatement toCode] stringByAppendingString:@"\n"];

        NSString *exported = [ctx getExportedVars];
        if(exported)
        {
            result = [result stringByAppendingString:exported];
        }
        result = [result stringByAppendingString:tmp];
        [ctx restoreExported];
    }
    
    StatementsNode *nextStatements =  (StatementsNode *)self.next;
    if(nextStatements)
    {
        nextStatements.firstStatement = NO;
        result = [result stringByAppendingString:[nextStatements toCode]];
    }

    if (self.firstStatement)
    {
        [ctx restoreSymbols];
    }
    
    return result;
}

- (NSInteger) getStatementsCount
{
    int result = 1;
    StatementsNode *item = (StatementsNode *)self.next;
    StatementsNode *valid = nil;
    while ( (valid = item) != nil)
    {
        result++;
        item = (StatementsNode *)[valid next];
    }
    return result;
}
@end
