//
//  Types.m
//
//  Created by Gregory Casamento on 10/20/14.
//

#import "Types.h"
#import "AST.h"

@class NamedExpression;

@implementation GenericType

- (id)initWithType: (SwiftType)aType
{
    self = [super init];
    if(self != nil)
    {
        self.type = aType;
    }
    return self;
}

- (GenericType *) operate: (NSString *)op
                         : (GenericType *)other
{
    if( [op isEqualToString: @"==="]
        || [op isEqualToString: @"=="]
        || [op isEqualToString: @"&&"]
        || [op isEqualToString: @"||"] )
    {
        return [[GenericType alloc] initWithType:BOOLEAN];
    }
    else if( [op isEqualToString: @"="] )
    {
        return other;
    }
    else if (self.type == STRING || other.type == STRING)
    {
        return [[GenericType alloc] initWithType: STRING];
    }
    else
    {
        return self;
    }
}

- (NSString *) customBinaryOperator: (ASTNode *)myNode
                                   : (NSString *)op
                                   : (ASTNode *)otherNode
{
    return nil;
}

- (GenericType *) fromTypeIdentifier: (NSString *)name
{
    if ([name isEqualToString: @"String"])
    {
        return [[GenericType alloc] initWithType:STRING];
    }
    else if ([name isEqualToString: @"Int"])
    {
        return [[GenericType alloc] initWithType:NUMBER];
    }
    else
    {
        return [[GenericType alloc] initWithType:UNKOWN];
    }
}

@end

@implementation IndirectionType
- (id) initWithPointer: (GenericType *)pointer
{
    self = [super initWithType: pointer.type];
    if(self != nil)
    {
        self.pointer = pointer;
    }
    return self;
}

- (void) update: (GenericType *)pointer
{
    
}
@end

@implementation TupleType

- (id) initWithList: (ExpressionList *)list
{
    self = [super initWithType: TUPLE];
    if(self != nil)
    {
        ExpressionList *item = list;
        int index = 0;
        id validItem = nil;
        
        self.names = [[NSMutableArray alloc] initWithCapacity:10];
        self.types = [[NSMutableArray alloc] initWithCapacity:10];
        
        while((validItem = item) != nil)
        {
            NamedExpression *namedExpression = nil;
            NamedExpression *expression = nil;
            if ((namedExpression = [validItem current]) != nil)
            {
                [self addType: namedExpression.name
                             : namedExpression.type];
            }
            else if((expression = validItem.current) != nil)
            {
                NSString *str = [NSString stringWithFormat:@"%d",index];
                [self addType: str
                             : expression.type];
            }
            ++index;
            item = [validItem next];
        }
    }
}

- (void) addType: (NSString *)name
                : (GenericType *)type
{
    [self.names addObject:name];
    [self.types addObject:type];
}

- (GenericType *) getTypeForIndex:(int)index
{
    return (GenericType *)[self.types objectAtIndex:index];
}
@end

// ArrayType...
@implementation ArrayType: GenericType
- (id) initWithInnerType: (GenericType *)innerType
{
    self = [super initWithType:ARRAY];
    if(self != nil)
    {
        self.innerType = innerType;
    }
    return self;
}

- (NSString *)customBinaryOperator:(ASTNode *)myNode :(NSString *)op :(ASTNode *)otherNode
{
    if([op isEqualToString:@"+="])
    {
        if(otherNode.type == ARRAY)
        {
            return [NSString stringWithFormat:@"[%@ addObjectsFromArray:%@]",[myNode toCode], [otherNode toCode]];
        }
        else
        {
            return [NSString stringWithFormat:@"[%@ addObjectsFromArray:%@]",[myNode toCode], [otherNode toCode]];
        }
    }
}
@end

// DictionaryType...
@implementation DictionaryType: GenericType
- (id) initWithInnerType: (GenericType *)innerType
{
    self = [super initWithType:DICTIONARY];
    if(self != nil)
    {
        self.innerType = innerType;
    }
    return self;
}
@end

// FunctionType...
@implementation FunctionType: GenericType
- (id) initWithArgumentTypes: (NSMutableArray *)argumentTypes
                  returnType: (GenericType *)returnType
{
    if((self = [super initWithType:DICTIONARY]) != nil)
    {
        self.argumentTypes = [argumentTypes copy];
        self.returnType = returnType;
    }
    return self;
}

- (id) initWithArgsType:(GenericType *)argsType
             returnType:(GenericType *)returnType
{
    self = [super initWithType:DICTIONARY];
    
    if(self)
    {
        TupleType *tuple = nil;
        if([argsType isKindOfClass:[TupleType class]])
        {
            tuple = (TupleType *)argsType;
        }
        
        if(tuple != nil)
        {
            [self.argumentTypes addObjectsFromArray:tuple.types];
        }
        
        self.returnType = returnType;
    }
    
    return self;
}
@end
