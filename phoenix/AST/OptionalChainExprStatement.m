#import "AST.h"

@implementation OptionalChainExprStatement

@synthesize optChainExpr;

- (id) initWithOptChainExpr:  (ASTNode *)anoptChainExpr
{
    self = [super init];
    if(self)
    {
        self.optChainExpr = anoptChainExpr;
    }
    return self;
}

- (NSString *)toCode
{
    ASTNode *expr = self.optChainExpr;
    if(expr)
    {
        return [expr toCode];
    }
    return @"";
}

@end
