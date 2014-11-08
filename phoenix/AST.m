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
    NSRange range = NSMakeRange(0, [code length]);
    NSString *result = [code stringByReplacingOccurrencesOfString:@"\n"
                                                       withString:@"\n\t"
                                                          options: NSCaseInsensitiveSearch
                                                            range: range];
    
    if( [result hasSuffix:@"\t"] )
    {
        result = [result substringToIndex:
                  [result lengthOfBytesUsingEncoding:NSUTF16StringEncoding] - 1];
    }
    result = [@"\t" stringByAppendingString: result];
    return result;
}

// Define a subclass for future expansion...
@implementation ASTSymbolTable : NSMutableDictionary
@end

// Context
@implementation ASTContext

// Methods.
- (NSString *)generateID
{
    return nil;
}

- (void) exportVar: (NSString *)name
{
    return ;
}

- (NSString *)getExportedVars
{
    return nil;
}

- (void) saveExported
{
    return ;
}

- (void) restoreExported
{
    return ;
}

- (void) saveSymbols
{
    return ;
}

- (void) restoreSymbols
{
    return ;
}

- (void) addSymbolName: (NSString *)name
                  type: (GenericType *)type
{
    return ;
}

- (GenericType *)inferType: (NSString *)name
{
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
    return nil;
}

- (GenericType *) inferType
{
    return nil;
}

- (void) setType: (GenericType *)type
{
    return;
}

- (void) setTypeIfEmpty: (GenericType *)type
{
    return;
}

@end

// Literal expression...
@implementation LiteralExpression
- (id) init: (NSString *)literal
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

// Identifier expression...
@implementation IdentifierExpression

- (id) init: (NSString *)identifier
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

@implementation BinaryOperator
- (id) initWithRightOperand: (ASTNode *)rightOperand
             binaryOperator: (NSString *)binaryOperator
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
