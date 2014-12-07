#import "AST.h"

@implementation PostfixOperator

@synthesize operand, postfixOperator;

- (id) init: (ASTNode *)anoperand
           : (NSString *)apostfixOperator;
{
    self = [super init];
    if(self)
    {
        self.operand = anoperand;
        self.postfixOperator = apostfixOperator;
    }
    return self;
}

- (NSString *) toCode
{
    return [NSString stringWithFormat:@"%@%@", [self.operand toCode], self.postfixOperator];
}

- (GenericType *) inferType
{
    return [self.operand getType];
}
@end
