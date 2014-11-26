//
//  Types.m
//
//  Created by Gregory Casamento on 10/20/14.
//

#import "Types.h"
#import "AST.h"

@class NamedExpression;

@implementation GenericType

@synthesize type;

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
        return [[GenericType alloc] initWithType:TYPE_BOOLEAN];
    }
    else if( [op isEqualToString: @"="] )
    {
        return other;
    }
    else if (self.type == TYPE_STRING || other.type == TYPE_STRING)
    {
        return [[GenericType alloc] initWithType: TYPE_STRING];
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

+ (GenericType *) fromTypeIdentifier: (NSString *)name
{
    if ([name isEqualToString: @"String"])
    {
        return [[GenericType alloc] initWithType:TYPE_STRING];
    }
    else if ([name isEqualToString: @"Int"])
    {
        return [[GenericType alloc] initWithType:TYPE_NUMBER];
    }
    else
    {
        return [[GenericType alloc] initWithType:TYPE_UNKNOWN];
    }
}

@end

@implementation IndirectionType

@synthesize pointer;

- (id) initWithPointer: (GenericType *)apointer
{
    self = [super initWithType: apointer.type];
    if(self != nil)
    {
        self.pointer = apointer;
    }
    return self;
}

- (void) update: (GenericType *)pointer
{
    
}
@end

@implementation TupleType

@synthesize names, types;

- (id) initWithList: (ExpressionList *)list
{
    self = [super initWithType: TYPE_TUPLE];
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
            ExpressionList *vItem = (ExpressionList *)validItem;
            if ((namedExpression = (NamedExpression *)[vItem current]) != nil)
            {
                [self addType: namedExpression.name
                             : namedExpression.type];
            }
            else if((expression = (NamedExpression *)[vItem current]) != nil)
            {
                NSString *str = [NSString stringWithFormat:@"%d",index];
                [self addType: str
                             : expression.type];
            }
            ++index;
            item = [vItem next];
        }
    }
    return self;
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

@synthesize innerType;

- (id) initWithInnerType: (GenericType *)aninnerType
{
    self = [super initWithType:TYPE_ARRAY];
    if(self != nil)
    {
        self.innerType = aninnerType;
    }
    return self;
}

- (NSString *)customBinaryOperator:(ASTNode *)myNode :(NSString *)op :(ASTNode *)otherNode
{
    if([op isEqualToString:@"+="])
    {
        if(otherNode.type.type == TYPE_ARRAY)
        {
            return [NSString stringWithFormat:@"[%@ addObjectsFromArray:%@]",[myNode toCode], [otherNode toCode]];
        }
        else
        {
            return [NSString stringWithFormat:@"[%@ addObjectsFromArray:%@]",[myNode toCode], [otherNode toCode]];
        }
        
        return [super customBinaryOperator:myNode :op :otherNode];
    }
    return nil;
}
@end

// DictionaryType...
@implementation DictionaryType: GenericType

@synthesize innerType;

- (id) initWithInnerType: (GenericType *)aninnerType
{
    self = [super initWithType:TYPE_DICTIONARY];
    if(self != nil)
    {
        self.innerType = aninnerType;
    }
    return self;
}
@end

// FunctionType...
@implementation FunctionType: GenericType

@synthesize argumentTypes, returnType;

- (id) initWithArgumentTypes: (NSMutableArray *)anargumentTypes
                  returnType: (GenericType *)areturnType
{
    if((self = [super initWithType:TYPE_DICTIONARY]) != nil)
    {
        self.argumentTypes = [anargumentTypes copy];
        self.returnType = areturnType;
    }
    return self;
}

- (id) initWithArgsType:(GenericType *)anargsType
             returnType:(GenericType *)areturnType
{
    self = [super initWithType:TYPE_DICTIONARY];
    
    if(self)
    {
        TupleType *tuple = nil;
        if([anargsType isKindOfClass:[TupleType class]])
        {
            tuple = (TupleType *)anargsType;
        }
        
        if(tuple != nil)
        {
            [self.argumentTypes addObjectsFromArray:tuple.types];
        }
        
        self.returnType = areturnType;
    }
    
    return self;
}
@end
