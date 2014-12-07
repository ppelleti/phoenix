#import "AST.h"

@implementation ASTNode

@dynamic type;

- (id) init
{
    self = [super init];
    if(self)
    {
        type = nil;
        [self retain];
    }
    return self;
}

- (NSString *)toCode
{
    return nil;
}

- (GenericType *) getType
{
    GenericType *cached = type;
    if(cached)
    {
        return cached;
    }
    type = [self inferType];
    return type ? type : [[GenericType alloc] initWithType:TYPE_UNKNOWN];
}

- (GenericType *) inferType
{
    return nil;
}

- (void) setType: (GenericType *)atype
{
    type = atype;
    [type retain];
}

- (void) setTypeIfEmpty: (GenericType *)atype
{
    if(self.type == nil)
    {
        type = atype;
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ : %@",[super description],[self toCode]];
}

@end
