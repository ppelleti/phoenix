//
//  AST.m
//  phoenix
//
//  Created by Gregory Casamento on 10/29/14.
//  Copyright (c) 2014 indie. All rights reserved.
//

#import "AST.h"
#import <math.h>

#define AS(X,Y) ([X class] == Y)?X:nil

NSString *tabulate(NSString *code)
{
    NSRange range = NSMakeRange(0, [code lengthOfBytesUsingEncoding:NSUTF8StringEncoding]);
    NSString *result = [code stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@"\n\t"
                                                          options: NSCaseInsensitiveSearch
                                                            range: range];
    
    if( [result hasSuffix:@"\t"] )
    {
        result = [result substringToIndex:
                  [result lengthOfBytesUsingEncoding:NSUTF8StringEncoding] - 1];
    }
    result = [@"\t" stringByAppendingString: result];
    return result;
}

@interface NSString (Extension)
- (NSInteger) toInt;
@end

@implementation NSString (Extension)

- (NSInteger)toInt
{
    NSError *error = nil;
    NSRegularExpression *regEx = [NSRegularExpression regularExpressionWithPattern:@"[-+]?[0-9]+"
                                                                           options:NSRegularExpressionCaseInsensitive
                                                                             error:&error];
    if([regEx matchesInString:self options:NSMatchingAnchored
       range:NSMakeRange(0, [self length])])
    {
        return [self integerValue];
    }
    return NAN;
}

@end

// Define a subclass for future expansion...
@implementation ASTSymbolTable : NSMutableDictionary
@end

// Context
@implementation ASTContext

- (id) init
{
    if(ctx != nil)
    {
        return ctx;
    }
    else
    {
        self = [super init];
        if(self != nil)
        {
            ctx = self;  // set global context...
            self.exportedVars = [NSMutableArray array];  // array of arrays of exported variables...
            self.exportedIndex = 0;
            self.symbols = [NSMutableArray array];  // Array of ASTSymbolTable objects...
            self.symbolsIndex = -1;
            self.generateIDIndex = 0;
        }
        return self;
    }
    return nil;
}

- (NSString *)variableDeclaration
{
    return @"id"; // temporary
}

- (NSString *)declarationSeparator
{
    return @","; // temporary...
}

// Methods.
- (NSString *)generateID
{
    return [NSString stringWithFormat:@"_ref%ld",
            (long)self.generateIDIndex++];
}

- (BOOL) _find: (NSString *)name
{
    if([self.exportedVars count] < self.symbolsIndex)
    {
        [self saveExported];
    }
    
    NSArray *array = [self.exportedVars objectAtIndex:self.exportedIndex];
    return [array containsObject:name];
}

- (void) exportVar: (NSString *)name
{
    if(![self _find:name])
    {
        [[self.exportedVars objectAtIndex:self.exportedIndex] addObject:name];
    }
}

- (NSString *)getExportedVars
{
    if ([[self.exportedVars objectAtIndex: self.exportedIndex] count] > 0)
    {
        NSString *result = @"";
        result = [result stringByAppendingString:[self variableDeclaration]];
        for (NSString *variable in [self.exportedVars objectAtIndex:self.exportedIndex])
        {
            result = [result stringByAppendingString:
                      [variable stringByAppendingString: [self declarationSeparator]]];
        }
        
        result = [result substringFromIndex:
                  [result lengthOfBytesUsingEncoding:NSUTF8StringEncoding] - 1];
        result = [result stringByAppendingString:@";\n"];
        return result;
    }
    return nil;
}

- (void) saveExported
{
    self.exportedIndex++;
    [self.exportedVars addObject:[NSMutableArray array]];
}

- (void) restoreExported
{
    if(self.exportedIndex > 0)
    {
        [self.exportedVars removeLastObject];
        self.exportedIndex--;
    }
}

- (void) saveSymbols
{
    self.symbolsIndex++;
    [self.symbols addObject:[NSMutableArray array]];
}

- (void) restoreSymbols
{
    if(self.symbolsIndex > 0)
    {
        [self.symbols removeLastObject];
        self.symbolsIndex--;
    }
}

- (void) addSymbolName: (NSString *)name
                  type: (GenericType *)type
{
    if([self.symbols count] < self.symbolsIndex)
    {
        [self.symbols addObject:[ASTSymbolTable dictionary]];
    }
    [[self.symbols objectAtIndex:self.symbolsIndex] setObject:type
                                                       forKey:name];
}

- (GenericType *)inferSymbol: (NSString *)name
{
    for(NSInteger i = self.symbolsIndex; i >= 0; --i)
    {
        GenericType *type = [[self.symbols objectAtIndex:i] objectForKey:name];
        if(type != nil)
        {
            return type;
        }
    }
    return nil;
}

@end

// Node
@implementation ASTNode

- (NSString *)toCode
{
    return nil;
}

- (GenericType *) getType
{
    GenericType *cached = self.type;
    if(cached)
    {
        return cached;
    }
    self.type = [self inferType];
    return self.type ? self.type : [[GenericType alloc] initWithType:TYPE_UNKNOWN];
}

- (GenericType *) inferType
{
    return nil;
}

- (void) setType: (GenericType *)type
{
    self.type = type;
}

- (void) setTypeIfEmpty: (GenericType *)type
{
    if(self.type == nil)
    {
        self.type = type;
    }
}

@end

// Literal expression...
@implementation LiteralExpression
- (id) init: (NSString *)literal
{
    self = [super init];
    if(self)
    {
        self.value = literal;
    }
    return self;
}

- (NSString *) toCode
{
    return self.value;
}

- (GenericType *) inferType
{
    if ([self.value isEqualToString: @"true"] ||
        [self.value isEqualToString: @"false"])
    {
        return [[GenericType alloc] initWithType:TYPE_BOOLEAN];
    }
    else if ([self.value hasPrefix: @"\""])
    {
        return [[GenericType alloc] initWithType:TYPE_STRING];
    }
    else {
        return [[GenericType alloc] initWithType:TYPE_NUMBER];
    }
}

@end

// Identifier expression...
@implementation IdentifierExpression

- (id) init: (NSString *)identifier
{
    self = [super init];
    if(self)
    {
        self.name = identifier;
    }
    return self;
}

- (NSString *) toCode
{
    return self.name;
}

- (GenericType *) inferType
{
    return [ctx inferSymbol:self.name];
}

@end

@implementation BinaryOperator
- (id) initWithRightOperand: (ASTNode *)rightOperand
             binaryOperator: (NSString *)binaryOperator
{
    self = [super init];
    if(self)
    {
        self.rightOperand = rightOperand;
        self.binaryOperator = binaryOperator;
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

@implementation AssignmentOperator

- (id) initWithRightOperand: (ASTNode *)rightOperand
{
    self = [super init];
    if(self)
    {
        self.rightOperand = rightOperand;
    }
    return self;
}

- (NSString *) toCode
{
    return [NSString stringWithFormat:@" = %@",self.rightOperand];
}

- (GenericType *) inferType
{
    return [self.rightOperand getType];
}

@end

@implementation TernaryOperator
- (id) initWithTrueOperand: (ASTNode *)trueOperand
              falseOperand: (ASTNode *)falseOperand
{
    self = [super init];
    if(self)
    {
        self.trueOperand = trueOperand;
        self.falseOperand = falseOperand;
    }
    return self;
}

- (NSString *) toCode
{
    return [NSString stringWithFormat:@" ? %@ : %@",
            [self.trueOperand toCode],
            [self.falseOperand toCode]];
}

- (GenericType *) inferType
{
    return [self.trueOperand getType];
}
@end

@implementation PrefixOperator
- (id) init: (ASTNode *)operand
           : (NSString *)prefixOperator;
{
    self = [super init];
    if(self)
    {
        self.operand = operand;
        self.prefixOperator = prefixOperator;
    }
    return self;
}

- (NSString *) toCode
{
    return [NSString stringWithFormat:@"%@%@",self.prefixOperator, [self.operand toCode]];
}

- (GenericType *) inferType
{
    return [self.operand getType];
}

@end

@implementation PostfixOperator
- (id) init: (ASTNode *)operand
           : (NSString *)postfixOperator;
{
    self = [super init];
    if(self)
    {
        self.operand = operand;
        self.postfixOperator = postfixOperator;
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

///
@implementation BinaryExpression


- (id) initWithExpression: (ASTNode *)expression
{
    self = [super init];
    if(self)
    {
        self.current = expression;
    }
    return self;
}

- (id) initWithExpression: (ASTNode *)expression
                     next: (BinaryExpression *)next
{
    self = [super init];
    if(self)
    {
        self.current = expression;
        self.next = next;
    }
    return self;
}

- (NSString *) leftAndRightTypeToCodeLeft: (ParenthesizedExpression *)left
                              right: (ParenthesizedExpression *)right
{
    NSString *result = @"";
    NSArray *names = [left toExpressionArray];
    NSArray *values = [right toExpressionArray];
    NSUInteger i = 0;
    for (i = 0; i < [names count]; ++i)
    {
        if (i >= [values count])
        {
            break;
        }
        
        [names[i] setTypeIfEmpty:[[values objectAtIndex:i] getType]]; //infere type from assignment if needed
        NSString *string = [NSString stringWithFormat:@"((%@) = (%@)), ",[[names objectAtIndex:i] toCode], [[values objectAtIndex:i]  toCode]];
        result = [result stringByAppendingString:string];
    }
    result = [result substringToIndex: [result lengthOfBytesUsingEncoding:NSUTF8StringEncoding] - 2];
    return result;
}

- (NSString *) leftTupleAndRightExpressionToCodeLeft: (ParenthesizedExpression *)left
                                               right: (ASTNode *)right
{
    NSString *tupleID = @"";
    LiteralExpression *literal = nil;
    IdentifierExpression *identifier = nil;
    if((literal = (LiteralExpression *)right) != nil)
    {
        tupleID = [literal toCode];
    }
    else if ((identifier = (IdentifierExpression *)right) != nil)
    {
        tupleID = [identifier toCode];
    }
    else
    {
        NSString *varName = [NSString stringWithFormat: @"%@ = %@", tupleID,
                             [right toCode]];
        tupleID = [ctx generateID];
        [ctx exportVar: varName];
    }
    
    NSArray *names = [left toExpressionArray];
    NSString *result = @"";
    TupleType *tupleType = nil;
    
    if ((tupleType = (TupleType *)[right getType]) != nil)
    {
        //known tuple type
        NSArray *tupleMembers = [tupleType names];
        int i = 0;
        for ( i = 0; i < [names count]; ++i )
        {
            [names[i] setTypeIfEmpty: [tupleType getTypeForIndex: i]]; //infere type from assignment if needed
            NSInteger number = [tupleMembers[i] toInt];
            if(isnan(number) == NO)
            {
                NSString *string = [NSString stringWithFormat:@"%@ = %@[%ld]",[[names objectAtIndex:i]  toCode], tupleID, (long)number];
                result = [result stringByAppendingString:string];
            }
            else
            {
                NSString *string = [NSString stringWithFormat:@"%@ = %@[%@]",[[names objectAtIndex:i]  toCode], tupleID, [tupleMembers objectAtIndex:i]];
                result = [result stringByAppendingString:string];
            }
        }
    }
    else {
        //unkown tuple type
        NSInteger i = 0;
        for (i = 0; i < names.count; ++i)
        {
            NSString *string = [NSString stringWithFormat:@"%@ = %@[Object.keys(%@)[%ld], ", [[names objectAtIndex:i] toCode], tupleID, tupleID, i];
            result = [result stringByAppendingString:string];
        }
    }
    
    result = [result substringToIndex: [result lengthOfBytesUsingEncoding:NSUTF8StringEncoding] - 2];
    return result;
}

- (NSString *)toCode
{
    //Check Tuple assignment binary expressions
    AssignmentOperator *assignment = (AssignmentOperator *)[self.next current];
    if (assignment != nil)
    {
        self.current.type = [assignment.rightOperand getType];
        //check left to right tuple assignment
        ParenthesizedExpression *leftTuple =  (ParenthesizedExpression *)[self current];
        ParenthesizedExpression *rightTuple = (ParenthesizedExpression *)assignment.rightOperand;
        
        if(leftTuple && [leftTuple isList] && rightTuple && [rightTuple isList])
        {
            return [self leftAndRightTypeToCodeLeft:leftTuple
                                              right:rightTuple];
        }
        else if(leftTuple && [leftTuple isList])
        {
            return  [self leftTupleAndRightExpressionToCodeLeft:leftTuple
                                                          right:assignment.rightOperand];
        }
    }
    
    BinaryOperator *binaryOperator = (BinaryOperator *)[self.next current];
    //check for custom operators. Example array +=
    if(binaryOperator)
    {
        NSString *customOperator = [[self.current getType]
                                    customBinaryOperator:self.current
                                    :binaryOperator.binaryOperator
                                    :binaryOperator.rightOperand];
        return customOperator;
    }

    //Generic binary expression
    NSString *result = @"";
    BinaryExpression *currentExpression = (BinaryExpression *)self.current;
    BinaryExpression *nextExpression = (BinaryExpression *)self.next;
    if(currentExpression)
    {
        result = [result stringByAppendingString: [currentExpression toCode]];
    }
    else if(nextExpression)
    {
        result = [result stringByAppendingString: [nextExpression toCode]];
    }

    return result;
}

- (GenericType *)inferType
{
    if([self current])
    {
        return nil;
    }
    
    GenericType *leftType = [self.current getType];
    if([[self.next current] class] == [BinaryOperator class])
    {
        BinaryOperator *op = (BinaryOperator *)[self.next current];
        return [leftType operate:[op binaryOperator]
                                :[op getType]];
    }
    else if([[self.next current] class] == [AssignmentOperator class])
    {
        AssignmentOperator *op = (AssignmentOperator *)[self.next current];
        self.current.type = [op getType];
        return [op getType];
    }
    
    return leftType;
}

@end

@implementation NamedExpression

- (id) initWithName: (NSString *)name
               expr: (ASTNode *)expr
{
    self = [super init];
    if(self)
    {
        self.name = name;
        self.expr = expr;
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

@implementation TypeExpression
- (id) initWithLinkedType: (GenericType *)linkedType
{
    self = [super init];
    if(self)
    {
        self.linkedType = linkedType;
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

@implementation ExpressionList
- (id)initWithExpr: (ASTNode *)expr
              next: (ExpressionList *)next
{
    self = [super init];
    if(self)
    {
        self.current = expr;
        self.next = next;
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

@implementation ParenthesizedExpression

- (id) initWithExpression: (ASTNode *)expression
{
    self = [super init];
    if(self)
    {
        self.expression = expression;
        self.allowInlineTuple = YES;
    }
    return nil;
}

- (NSString *) toInlineTuple: (ExpressionList *) list
{
    NSString *result = @"{";
    ExpressionList *item = list;
    int index = 0;
    ExpressionList *validItem = nil;
    ASTNode *expression = nil;
    
    while ((validItem = item) != nil)
    {
        NamedExpression *namedExpression = (NamedExpression *)(AS([validItem current], [NamedExpression class]));
        if (namedExpression)
        {
            NSString *string = [NSString stringWithFormat:@"%@: %@, ",
                                [namedExpression name],
                                [[namedExpression expr] toCode]];
            [result stringByAppendingString:string];
        }
        else if ((expression = [validItem current]) != nil)
        {
            NSString *string = [NSString stringWithFormat:@"%d: %@",index, [expression toCode]];
            result = [result stringByAppendingString:string]; // += "\(index): \(expression.toJS()), ";
        }
        ++index;
        item = validItem.next;
    }
    
    result = [result substringToIndex: [result lengthOfBytesUsingEncoding:NSUTF8StringEncoding] - 2]; //remove last ', '
    result = [result stringByAppendingString:@"}"];
    
    return result;
}

- (BOOL) isList
{
    ExpressionList *list = (ExpressionList *)(AS(self.expression,
                                                 [ExpressionList class]));
    if(list)
    {
        if([list next])
        {
            return YES;
        }
    }
    return NO;
}

- (NSArray *) toExpressionArray
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:10];
    ExpressionList *node = (ExpressionList *)(AS(self.expression, [ExpressionList class]));
    ExpressionList *item = nil;
    
    while((item = node) != nil)
    {
        [result addObject:[item current]];
        node = [item next];
    }
    
    return (NSArray *)result;
}

- (NSArray *) toTypesArray
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:10];
    ExpressionList *node = (ExpressionList *)(AS(self.expression, [ExpressionList class]));
    ExpressionList *item = nil;
    
    while((item = node) != nil)
    {
        [result addObject:[[item current] getType]];
        node = [item next];
    }
    
    return (NSArray *)result;
}

- (NSString *) toTupleInitializer: (NSString *)variableName
{
    ExpressionList *list = (ExpressionList *)(AS(self.expression, [ExpressionList class]));
    NSString *result = [variableName stringByAppendingString: @" = "];
    result = [result stringByAppendingString:[NSString stringWithFormat:@"%@ = %@", variableName, [self toInlineTuple: list]]];
    return result;
}

- (NSString *)toCode
{
    
    if (self.allowInlineTuple)
    {
        ExpressionList *list = (ExpressionList *)(AS(self.expression, [ExpressionList class]));
        if (list)
        {
            if (([list next]) != nil)
            {
                return [self toInlineTuple: list];
            }
        }
    }
    
    ExpressionList *expr = nil;
    if ((expr = (ExpressionList *)self.expression) != nil)
    {
        NSString *result = [NSString stringWithFormat:@"(%@)",[expr toCode]];
        return result;
    }

    return @"()";
}

- (GenericType *)inferType
{
    if (self.allowInlineTuple)
    {
        ExpressionList *list = (ExpressionList *)(AS(self.expression, [ExpressionList class]));
        ASTNode *item = nil;
        if(list != nil)
        {
            if( [list next] )
            {
                //mutiple elements = > tuple
                return [[TupleType alloc] initWithList:list];
            }
            else if ((item = [list current]) != nil)
            {
                //single element => not a tuple
                return [item getType];
            }
        }
    }
    
    ASTNode *expr = nil;
    if ((expr = (ASTNode *)self.expression) != nil)
    {
        return [expr getType];
    }
    
    return nil;
}

@end

@implementation FunctionCallExpression

- (id) initWithFunction: (ASTNode *)function
          parenthesized: (ParenthesizedExpression *)parenthesized
{
    self = [super init];
    if(self)
    {
        self.function = function;
        self.parenthesized = parenthesized;
    }
    return self;
}


- (NSString *)toCode
{
    self.parenthesized.allowInlineTuple = NO;
    return [self.function toCode];
}

- (GenericType *)inferType
{
    FunctionType *funcType = (FunctionType *)(AS([self.function getType], [FunctionType class]));
    if(funcType != nil)
    {
        return [funcType returnType];
    }
    return [[GenericType alloc] initWithType:TYPE_VOID];
}
@end

@implementation VariableDeclaration

- (id) initWithInitializer: (ExpressionList *)initializer
{
    self = [super init];
    if(self)
    {
        self.initializer = initializer;
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

@implementation ArrayLiteral: ASTNode

- (id) initWithItems: (ASTNode *)items
{
    self = [super init];
    if(self)
    {
        self.items = items;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = @"[";
    ASTNode *data = self.items;
    if(data != nil)
    {
        result = [result stringByAppendingString:[data toCode]];
    }
    return result;
}

- (GenericType *)inferType
{
    ExpressionList *node = (ExpressionList *)(AS(self.items,
                                                 [ExpressionList class]));
    ASTNode *item = [node current];
    if(item)
    {
        return [[ArrayType alloc] initWithInnerType:[item getType]];
    }
    return [[ArrayType alloc] initWithInnerType:
            [[GenericType alloc] initWithType:TYPE_UNKNOWN]];
}
@end

@implementation DictionaryLiteral : ASTNode


- (id) initWithPairs: (ASTNode *)pairs
{
    return nil;
}
- (NSString *)toCode
{
    return nil;
}
- (GenericType *)inferType
{
    return nil;
}
@end


@implementation DictionaryItem: ASTNode


- (id) initWithKey: (ASTNode *)key value: (ASTNode *)value
{
    return nil;
}
- (NSString *)toCode
{
    return nil;
}
- (GenericType *)inferType
{
    return nil;
}
@end


@implementation FunctionParameter : ASTNode

- (id) initWithInoutVal: (BOOL)inoutVal
                 letVal: (BOOL)letVal
                hashVal: (BOOL)hashVal
               external: (NSString *)external
                  local: (NSString *)local
                 defVal: (ASTNode *)defVal
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

- (GenericType *)inferType
{
    return nil;
}

@end


@implementation FunctionDeclaration : ASTNode

- (id) initWithName: (NSString *)name
          signature: (ASTNode *)signature
               body: (ASTNode *)body
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

- (GenericType *)inferType
{
    return nil;
}

@end

/*** Statements ***/

@implementation WhileStatement : ASTNode

- (id)initWithWhileCondition: (ASTNode *)whileCondition
                   codeBlock: (ASTNode *)codeBlock
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

@end


@implementation LabelStatement : ASTNode

- (id) initWithLabelName: (NSString *)labelName
                    loop: (ASTNode *)loop
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

@end

@implementation BreakStatement : ASTNode
- (id) initWithLabelId: (NSString *)labelName
{
    return nil;
}
- (NSString *)toCode
{
    return nil;
}
@end

@implementation ReturnStatement

- (id) initWithReturnExpr:  (ASTNode *)returnExpr
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

- (GenericType *)inferType
{
    return nil;
}

@end


@implementation OptionalChainExprStatement

- (id) initWithOptChainExpr:  (ASTNode *)optChainExpr
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

- (GenericType *)inferType
{
    return nil;
}

@end

@implementation IfStatement : ASTNode

- (id) initWithIfCondition: (ASTNode *)ifCondition
                      body: (ASTNode *)body
                elseClause: (ASTNode *)elseClause
{
    return nil;
}


- (NSString *)toCode
{
    return nil;
}

@end

@implementation ImportStatement : ASTNode

- (id) initWithPath: (NSString *)path
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

@end

@implementation StatementNode : ASTNode

- (id) initWithStatement: (ASTNode *)statement
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

@end

@implementation DeclarationStatement : ASTNode

- (id) initWithDeclaration: (ASTNode *)declaration
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}
@end

@implementation StatementsNode : ASTNode

- (id) initWithCurrent: (ASTNode *)current
{
    return nil;
}

- (id) initWithCurrent: (ASTNode *)current
                  next: (StatementsNode *)next
{
    return nil;
}

- (NSString *)toCode
{
    return nil;
}

- (NSInteger) getStatementsCount
{
    return 0;
}
@end
