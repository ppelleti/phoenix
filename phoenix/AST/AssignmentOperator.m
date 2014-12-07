#import "AST.h"

@implementation AssignmentOperator

@synthesize rightOperand;

- (id) initWithRightOperand: (ASTNode *)arightOperand
{
    self = [super init];
    if(self)
    {
        self.rightOperand = arightOperand;
    }
    return self;
}

- (NSString *) toCode
{
    return [NSString stringWithFormat:@" = %@",[self.rightOperand toCode]];
}

- (GenericType *) inferType
{
    return [self.rightOperand getType];
}

@end
