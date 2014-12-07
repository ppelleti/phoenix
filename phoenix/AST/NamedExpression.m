#import "AST.h"

@implementation NamedExpression

@synthesize name, expr;

- (id) initWithName: (NSString *)aname
               expr: (ASTNode *)anexpr
{
    self = [super init];
    if(self)
    {
        self.name = aname;
        self.expr = anexpr;
    }
    return self;
}

- (NSString *)toCode
{
    return [self.expr toCode];
}

- (GenericType *)inferType
{
    return [self.expr getType];
}

@end
