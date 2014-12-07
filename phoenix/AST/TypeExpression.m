#import "AST.h"

@implementation TypeExpression

@synthesize linkedType;

- (id) initWithLinkedType: (GenericType *)alinkedType
{
    self = [super init];
    if(self)
    {
        self.linkedType = alinkedType;
    }
    return self;
}

- (NSString *)toCode
{
    return @"";
}

- (GenericType *)inferType
{
    return self.linkedType;
}
@end
