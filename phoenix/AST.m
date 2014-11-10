//
//  AST.m
//  phoenix
//
//  Created by Gregory Casamento on 10/29/14.
//  Copyright (c) 2014 indie. All rights reserved.
//

#import "AST.h"

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

- (NSString *) toCode
{
    return nil;
}

- (GenericType *) inferType
{
    return [self.rightOperand getType];
}

@end

@implementation AssignmentOperator
- (id) initWithRightOperand: (ASTNode *)rightOperand
{
    return nil;
}

- (NSString *) toCode
{
    return nil;
}

- (GenericType *) inferType
{
    return nil;
}

@end

@implementation TernaryOperator
- (id) initWithTrueOperand: (ASTNode *)trueOperand
              falseOperand: (ASTNode *)falseOperand
{
    return nil;
}

- (NSString *) toCode
{
    return nil;
}

- (GenericType *) inferType
{
    return nil;
}

@end

@implementation PrefixOperator
- (id) init: (ASTNode *)operand
           : (NSString *)prefixOperator;
{
    return nil;
}

- (NSString *) toCode
{
    return nil;
}

- (GenericType *) inferType
{
    return nil;
}

@end

@implementation PostfixOperator
- (id) init: (ASTNode *)operand
           : (NSString *)prefixOperator;
{
    return nil;
}

- (NSString *) toCode
{
    return nil;
}

- (GenericType *) inferType
{
    return nil;
}

@end

///
@implementation BinaryExpression


- (id) initWithExpression: (ASTNode *)expression
{
    return nil;
}

- (id) initWithExpression: (ASTNode *)expression
                     next: (BinaryExpression *)next
{
    return nil;
}

- (void) leftAndRightTypeToCodeLeft: (ParenthesizedExpression *)left
                              right: (ParenthesizedExpression *)right
{
    return;
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

@implementation NamedExpression

- (id) initWithName: (NSString *)name
               expr: (ASTNode *)expr
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

@implementation TypeExpression
- (id) initWithLinkedType: (GenericType *)linkedType
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

@implementation ExpressionList


- (id)initWithExpr: (ASTNode *)expr
              next: (ExpressionList *)next
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

@implementation ParenthesizedExpression 

- (id) initWithExpression: (ASTNode *)expression
{
    return nil;
}

- (NSString *) toInlineTuple: (ExpressionList *) list
{
    return nil;
}

- (BOOL) isList
{
    return YES;
}

- (NSArray *) toExpressionArray
{
    return nil;
}

- (NSArray *) toTypesArray
{
    return nil;
}

- (NSString *) toTupleInitializer: (NSString *)variableName
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

@implementation FunctionCallExpression

- (id) initWithFunction: (ASTNode *)function
          parenthesized: (ParenthesizedExpression *)parenthesized
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

@implementation VariableDeclaration


- (id) initWithInitializer: (ExpressionList *)initializer
{
    return nil;
}
- (void) exportSymbols: (ASTNode *)expression
{
    return ;
}

- (NSString *) toCode
{
    return nil;
}

@end

@implementation ArrayLiteral: ASTNode


- (id) initWithItems: (ASTNode *)items
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
