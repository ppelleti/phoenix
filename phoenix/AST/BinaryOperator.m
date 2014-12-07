#import "AST.h"

@implementation BinaryOperator

@synthesize rightOperand, binaryOperator;

- (id) initWithRightOperand: (ASTNode *)arightOperand
             binaryOperator: (NSString *)abinaryOperator
{
    self = [super init];
    if(self)
    {
        self.rightOperand = arightOperand;
        self.binaryOperator = abinaryOperator;
    }
    return self;
}

- (NSString *) codeForIndex: (NSInteger)index
{
    return [NSString stringWithFormat:@"[%ld]",index];
}

- (NSString *) toCode
{
    if([self.binaryOperator isEqualToString:@"."])
    {
        NSString *right = [self.rightOperand toCode];
        NSInteger index = [right integerValue];
        if(!isnan(index))
        {
            return [self codeForIndex:index];
        }
        return [NSString stringWithFormat: @"%@%@",self.binaryOperator, right];
    }
    
    // else...
    return [NSString stringWithFormat: @" %@ %@",self.binaryOperator,
            [self.rightOperand toCode]];
}

- (GenericType *) inferType
{
    return [self.rightOperand getType];
}

@end
