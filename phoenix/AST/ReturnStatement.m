#import "AST.h"

@implementation ReturnStatement

@synthesize returnExpr;

- (id) initWithReturnExpr:  (ASTNode *)areturnExpr
{
    self = [super init];
    if(self)
    {
        self.returnExpr = areturnExpr;
    }
    return self;
}

- (NSString *)toCode
{
    ASTNode *expr = self.returnExpr;
    if (expr)
    {
        return [NSString stringWithFormat:@"return %@;", [expr toCode]];
    }
    return @"return;";
}

- (GenericType *)inferType
{
    ASTNode *expr = self.returnExpr;
    if (expr)
    {
        return [expr getType];
    }
    return [[GenericType alloc] initWithType:TYPE_VOID];
}

@end
