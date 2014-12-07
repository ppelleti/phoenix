#import "AST.h"

@implementation ExpressionList

@synthesize current, next;

- (id)initWithExpr: (ASTNode *)anexpr
              next: (ExpressionList *)anext
{
    self = [super init];
    if(self)
    {
        self.current = anexpr;
        self.next = anext;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = @"";
    ASTNode *currentExpression = self.current;
    if (currentExpression)
    {
        result = [result stringByAppendingString:[currentExpression toCode]];
    }
    
    ExpressionList *nextExpression = self.next;
    if (nextExpression)
    {
        result = [result stringByAppendingString: [NSString stringWithFormat:@", %@", [nextExpression toCode]]];
    }
    return result;
}

- (GenericType *)inferType
{
    NSMutableArray *types = [[NSMutableArray alloc] initWithCapacity:10];// :[GenericType] = [];
    ExpressionList *item = self; // var item:ExpressionList? = self;
    ExpressionList *valid = nil;
    while ((valid = item) != nil)
    {
        ExpressionList *expr = (ExpressionList *)[valid current];
        if  (expr)
        {
            [types addObject: [expr getType]];
        }
        item = [valid next];
    }
    
    //TODO: get less restrictive type instead of the first one
    return types.count > 0 ? types[0] : nil;
}
@end
