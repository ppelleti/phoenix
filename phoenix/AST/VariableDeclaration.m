#import "AST.h"

@implementation VariableDeclaration

@synthesize initializer;

- (id) initWithInitializer: (ExpressionList *)aninitializer
{
    self = [super init];
    if(self)
    {
        self.initializer = aninitializer;
    }
    return self;
}

- (void) exportSymbols: (ASTNode *)expression
{
    if(expression == nil)
    {
        return;
    }
    
    ParenthesizedExpression *tuple = (ParenthesizedExpression *)(AS(expression, [ParenthesizedExpression class]));
    if(tuple != nil)
    {
        NSArray *names = [tuple toExpressionArray];
        NSArray *types = [tuple toTypesArray];
        int i = 0;
        for(i = 0; i < [names count]; i++)
        {
            NSString *name = [[names objectAtIndex:i] toCode];
            if(self.exportVariables)
            {
                [ctx exportVar:name];
            }
            [ctx addSymbolName:name type:[types objectAtIndex:i]];
        }
    }
    else
    {
        NSString *name = [expression toCode];
        if(self.exportVariables)
        {
            [ctx exportVar:name];
        }
        [ctx addSymbolName:name type:[expression getType]];
    }
}

- (NSString *) toCode
{
    
    NSString *result = [self.initializer toCode];
    
    //export symbols and vars
    ExpressionList *node = self.initializer;
    ExpressionList *item = nil;
    while ((item = node) != nil)
    {
        BinaryExpression *binaryExpr = (BinaryExpression *)(AS([item current], [BinaryExpression class]));
        if (binaryExpr)
        {
            [self exportSymbols:[binaryExpr current]];
        }
        else
        {
            [self exportSymbols:[item current]];
        }
        node = item.next;
    }
    
    //avoid var if exporting variables
    if (self.exportVariables)
    {
        return result;
    }

    return [NSString stringWithFormat:@"id %@", result];
}

@end
