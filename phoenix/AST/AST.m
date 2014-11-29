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

@synthesize exportedIndex, exportedVars, symbols, symbolsIndex, generateIDIndex;

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

@synthesize type;

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

- (void) setType: (GenericType *)atype
{
    self.type = atype;
}

- (void) setTypeIfEmpty: (GenericType *)atype
{
    if(self.type == nil)
    {
        self.type = atype;
    }
}

@end

// Literal expression...
@implementation LiteralExpression

@synthesize value;

- (id) init: (NSString *)aliteral
{
    self = [super init];
    if(self)
    {
        self.value = aliteral;
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

@synthesize name;

- (id) init: (NSString *)anidentifier
{
    self = [super init];
    if(self)
    {
        self.name = anidentifier;
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
    return [NSString stringWithFormat:@" = %@",self.rightOperand];
}

- (GenericType *) inferType
{
    return [self.rightOperand getType];
}

@end

@implementation TernaryOperator
- (id) initWithTrueOperand: (ASTNode *)atrueOperand
              falseOperand: (ASTNode *)afalseOperand
{
    self = [super init];
    if(self)
    {
        self.trueOperand = atrueOperand;
        self.falseOperand = afalseOperand;
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

@synthesize operand, prefixOperator;

- (id) init: (ASTNode *)anoperand
           : (NSString *)aprefixOperator;
{
    self = [super init];
    if(self)
    {
        self.operand = anoperand;
        self.prefixOperator = aprefixOperator;
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

///
@implementation BinaryExpression

@synthesize current;

- (id) initWithExpression: (ASTNode *)anexpression
{
    self = [super init];
    if(self)
    {
        self.current = anexpression;
    }
    return self;
}

- (id) initWithExpression: (ASTNode *)anexpression
                     next: (BinaryExpression *)anext
{
    self = [super init];
    if(self)
    {
        self.current = anexpression;
        self.next = anext;
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

@implementation ExpressionList

@synthesize current, next;

- (id)initWithExpr: (ASTNode *)anexpr
              next: (ExpressionList *)anext
{
    self = [super init];
    if(self)
    {
        self.current = anexpr;
        self.next = anext;
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

@synthesize expression, allowInlineTuple;

- (id) initWithExpression: (ASTNode *)anexpression
{
    self = [super init];
    if(self)
    {
        self.expression = anexpression;
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
    ASTNode *expr = nil;
    
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
        else if ((expr = [validItem current]) != nil)
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

@synthesize function, parenthesized;

- (id) initWithFunction: (ASTNode *)afunction
          parenthesized: (ParenthesizedExpression *)aparenthesized
{
    self = [super init];
    if(self)
    {
        self.function = afunction;
        self.parenthesized = aparenthesized;
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

@implementation ArrayLiteral: ASTNode

@synthesize items;

- (id) initWithItems: (ASTNode *)anitems
{
    self = [super init];
    if(self)
    {
        self.items = anitems;
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
    result = [result stringByAppendingString:@"]"];
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

@synthesize pairs;

- (id) initWithPairs: (ASTNode *)apairs
{
    self = [super init];
    if(self)
    {
        self.pairs = apairs;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = @"{";
    ASTNode *data = self.pairs;
    if(data)
    {
        NSString *string = tabulate([[data toCode] stringByAppendingString:@"\n"]);
        result = [result stringByAppendingString:string];
    }
    result = [result stringByAppendingString:@"}"];
    return result;
}

- (GenericType *)inferType
{
    ExpressionList *item = (ExpressionList *)(AS(self.pairs, [ExpressionList class]));
    ASTNode *current = [item current];
    if(current)
    {
        return [[DictionaryType alloc] initWithInnerType:[item getType]];
    }

    return [[DictionaryType alloc] initWithInnerType:
            [[GenericType alloc] initWithType:TYPE_UNKNOWN]];
}

@end


@implementation DictionaryItem: ASTNode

@synthesize key, value;

- (id) initWithKey: (ASTNode *)akey value: (ASTNode *)avalue
{
    self = [super init];
    if(self)
    {
        self.key = akey;
        self.value = avalue;
    }
    return self;
}

- (NSString *)toCode
{
    return [[[@"\n" stringByAppendingString: [self.key toCode]]
             stringByAppendingString:@" : "]
            stringByAppendingString:[self.value toCode]];
}

- (GenericType *)inferType
{
    return [self.value getType];
}

@end


@implementation FunctionParameter : ASTNode

@synthesize inoutVal, letVal, hashVal, external, local, defVal;

- (id) initWithInoutVal: (BOOL)aninoutVal
                 letVal: (BOOL)aletVal
                hashVal: (BOOL)ahashVal
               external: (NSString *)anexternal
                  local: (NSString *)alocal
                 defVal: (ASTNode *)adefVal
{
    self = [super init];
    if(self)
    {
        self.inoutVal = aninoutVal;
        self.letVal = aletVal;
        self.hashVal = ahashVal;
        self.external = anexternal;
        self.local = alocal;
        self.defVal = adefVal;
    }
    return self;
}

- (NSString *)toCode
{
    return self.local ? self.local : self.external;
}

@end


@implementation FunctionDeclaration : ASTNode

@synthesize name, signature, body;

- (id) initWithName: (NSString *)aname
          signature: (ASTNode *)asignature
               body: (ASTNode *)abody
{
    self = [super init];
    if(self)
    {
        self.name = aname;
        self.signature = asignature;
        self.body = abody;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = [NSString stringWithFormat:@"function %@ (", self.name]; // "function " + self.name + "(";
    ASTNode *parameters = self.signature;
    if (parameters)
    {
        [result stringByAppendingString:[parameters toCode]];
    }
    [result stringByAppendingString:@") {\n"];

    ASTNode *statements = self.body;
    if(statements)
    {
        NSString *string = tabulate([statements toCode]);
        result = [result stringByAppendingString:string];
    }

    result = [result stringByAppendingString: @"}"];
    return result;
}

@end

/*** Statements ***/

@implementation WhileStatement : ASTNode

@synthesize whileCondition, codeBlock;

- (id)initWithWhileCondition: (ASTNode *)awhileCondition
                   codeBlock: (ASTNode *)acodeBlock
{
    self = [super init];
    if(self)
    {
        self.whileCondition = awhileCondition;
        self.codeBlock = acodeBlock;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *result = @"while";
    
    result = [result stringByAppendingString:[NSString stringWithFormat:@"( %@ ) { \n", [self.whileCondition toCode]]];
    ASTNode *statements = self.codeBlock;
    if(statements)
    {
        NSString *string = tabulate([statements toCode]);
        result = [result stringByAppendingString:string];
    }
    
    
    result = [result stringByAppendingString:@"}"];
    return result;
}

@end


@implementation LabelStatement : ASTNode

@synthesize labelName, loop;

- (id) initWithLabelName: (NSString *)alabelName
                    loop: (ASTNode *)aloop
{
    self = [super init];
    if(self)
    {
        self.labelName = alabelName;
        self.loop = aloop;
    }
    return self;
}

- (NSString *)toCode
{
    return [NSString stringWithFormat:@"%@:\n%@",self.labelName,
            [self.loop toCode]];
}

@end

@implementation BreakStatement : ASTNode

@synthesize labelName;

- (id) initWithLabelId: (NSString *)alabelName
{
    self = [super init];
    if(self)
    {
        self.labelName = alabelName;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *identifier = self.labelName;
    if(identifier)
    {
        return [NSString stringWithFormat:@"break %@;",identifier];
    }
    return @"break;";
}
@end

@implementation ReturnStatement

@synthesize returnExpr;

- (id) initWithReturnExpr:  (ASTNode *)areturnExpr
{
    self = [super init];
    if(self)
    {
        self.returnExpr = areturnExpr;
    }
    return self;
}

- (NSString *)toCode
{
    ASTNode *expr = self.returnExpr;
    if (expr)
    {
        return [NSString stringWithFormat:@"return %@;", [expr toCode]];
    }
    return @"return;";
}

- (GenericType *)inferType
{
    ASTNode *expr = self.returnExpr;
    if (expr)
    {
        return [expr getType];
    }
    return [[GenericType alloc] initWithType:TYPE_VOID];
}

@end


@implementation OptionalChainExprStatement

@synthesize optChainExpr;

- (id) initWithOptChainExpr:  (ASTNode *)anoptChainExpr
{
    self = [super init];
    if(self)
    {
        self.optChainExpr = anoptChainExpr;
    }
    return self;
}

- (NSString *)toCode
{
    ASTNode *expr = self.optChainExpr;
    if(expr)
    {
        return [expr toCode];
    }
    return @"";
}

@end

@implementation IfStatement : ASTNode

@synthesize ifCondition, body, elseClause;

- (id) initWithIfCondition: (ASTNode *)anifCondition
                      body: (ASTNode *)abody
                elseClause: (ASTNode *)anelseClause
{
    self = [super init];
    if(self)
    {
        self.ifCondition = anifCondition;
        self.body = abody;
        self.elseClause = anelseClause;
    }
    return self;
}


- (NSString *)toCode
{
    NSString *result = @"if (";
    result = [result stringByAppendingString:[self.ifCondition toCode]];
    result = [result stringByAppendingString:@") {\n"];
    ASTNode *statements = self.body;
    if(statements)
    {
        NSString *string = tabulate([statements toCode]);
        result = [result stringByAppendingString:string];
    }
    result = [result stringByAppendingString:@"}"];
    ASTNode *next = self.elseClause;
    if(next)
    {
        result = [result stringByAppendingString:@"\nelse"];
        if([next isKindOfClass:[IfStatement class]])
        {
            result = [result stringByAppendingString:[next toCode]];
        }
        else
        {
            NSString *string = [NSString stringWithFormat:@"{\n %@ }",tabulate([next toCode])];
            result = [result stringByAppendingString:string];
        }
    }
    
    return result;
}

@end

@implementation ImportStatement : ASTNode

@synthesize path;

- (id) initWithPath: (NSString *)apath
{
    self = [super init];
    if(self)
    {
        self.path = apath;
    }
    return self;
}

- (NSString *)toCode
{
    NSString *pathRep = [NSString stringWithFormat:@"%@/%@.h",self.path, self.path];
    return [NSString stringWithFormat:@"#import <%@>\n",pathRep];
}

@end

@implementation StatementNode : ASTNode

@synthesize statement;

- (id) initWithStatement: (ASTNode *)astatement
{
    self = [super init];
    if(self)
    {
        self.statement = astatement;
    }
    return self;
}

- (NSString *)toCode
{
    return [NSString stringWithFormat:@"%@;",self.statement];
}

@end

@implementation DeclarationStatement : ASTNode

- (id) initWithDeclaration: (ASTNode *)adeclaration
{
    self = [super init];
    if(self)
    {
        self.declaration = adeclaration;
    }
    return self;
}

- (NSString *)toCode
{
    VariableDeclaration *varDeclaration = (VariableDeclaration *)(AS(self.declaration, [VariableDeclaration class]));
    if(varDeclaration)
    {
        varDeclaration.exportVariables = NO;
    }
    return [self.declaration toCode];
}
@end

@implementation StatementsNode : ASTNode

@synthesize current;

- (id) initWithCurrent: (ASTNode *)acurrent
{
    self = [super init];
    if(self)
    {
        self.current = acurrent;
    }
    return self;
}

- (id) initWithCurrent: (ASTNode *)acurrent
                  next: (StatementsNode *)anext
{
    self = [super init];
    if(self)
    {
        self.current = acurrent;
        self.next = anext;
    }
    return self;
}

- (NSString *)toCode
{
    if (self.firstStatement)
    {
        [ctx saveSymbols];
    }
    
    NSString *result = @"";
    ASTNode *currentStatement = self.current;
    if (currentStatement)
    {
        [ctx saveExported];
        NSString *tmp = [[currentStatement toCode] stringByAppendingString:@"\n"];

        NSString *exported = [ctx getExportedVars];
        if(exported)
        {
            result = [result stringByAppendingString:exported];
        }
        result = [result stringByAppendingString:tmp];
        [ctx restoreExported];
    }
    
    StatementsNode *nextStatements =  (StatementsNode *)self.next;
    if(nextStatements)
    {
        nextStatements.firstStatement = NO;
        result = [result stringByAppendingString:[nextStatements toCode]];
    }

    if (self.firstStatement)
    {
        [ctx restoreSymbols];
    }
    
    return result;
}

- (NSInteger) getStatementsCount
{
    int result = 1;
    StatementsNode *item = (StatementsNode *)self.next;
    StatementsNode *valid = nil;
    while ( (valid = item) != nil)
    {
        result++;
        item = (StatementsNode *)[valid next];
    }
    return result;
}
@end
