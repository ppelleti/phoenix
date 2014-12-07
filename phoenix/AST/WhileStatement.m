#import "AST.h"

@implementation WhileStatement

@synthesize whileCondition, codeBlock;

- (id)initWithWhileCondition: (ASTNode *)awhileCondition
                   codeBlock: (ASTNode *)acodeBlock
{
    self = [super init];
    if(self)
    {
        self.whileCondition = awhileCondition;
        self.codeBlock = acodeBlock;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = @"while";
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@"( %@ ) { \n", [self.whileCondition toCode]]];
    ASTNode *statements = self.codeBlock;
    if(statements)
    {
        NSString *string = tabulate([statements toCode]);
        result = [result stringByAppendingString:string];
    }
    
    
    result = [result stringByAppendingString:@"}"];
    return result;
}

@end
