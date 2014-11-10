//
//  AST.h
//  phoenix
//
//  Created by Gregory Casamento on 10/29/14.
//  Copyright (c) 2014 indie. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Types.h"

@class ParenthesizedExpression;

// Define a subclass for future expansion...
@interface ASTSymbolTable : NSMutableDictionary
@end

// Context
@interface ASTContext : NSObject

//exported variable declarations
@property (nonatomic, retain) NSMutableArray *exportedVars;
@property (nonatomic, assign) NSInteger exportedIndex;

//scoped symbols for type inference
@property (nonatomic, retain) NSMutableArray *symbols;
@property (nonatomic, assign) NSInteger symbolsIndex;

//index for IDS
@property (nonatomic, assign) NSInteger generateIDIndex;

- (NSString *) variableDeclaration;
- (NSString *) declarationSeparator;

// Methods.
- (NSString *)generateID;
- (void) exportVar: (NSString *)name;
- (NSString *)getExportedVars;
- (void) saveExported;
- (void) restoreExported;
- (void) saveSymbols;
- (void) restoreSymbols;
- (void) addSymbolName: (NSString *)name
                  type: (GenericType *)type;
- (GenericType *)inferSymbol: (NSString *)name;

@end

// Global context....
static ASTContext *ctx = nil;  // Initialized top ASTContext when first context is created...

// Node
@interface ASTNode: NSObject

@property (nonatomic, retain) GenericType *type;

- (NSString *)toCode;
- (GenericType *) getType;
- (GenericType *) inferType;
- (void) setType: (GenericType *)type;
- (void) setTypeIfEmpty: (GenericType *)type;

@end

// Literal expression...
@interface LiteralExpression: ASTNode
@property (nonatomic, retain) NSString *value;
- (id) init: (NSString *)literal;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

// Identifier expression...
@interface IdentifierExpression: ASTNode
@property (nonatomic, retain) NSString *value;
- (id) init: (NSString *)identifier;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

@interface BinaryOperator : ASTNode
- (id) initWithRightOperand: (ASTNode *)rightOperand
             binaryOperator: (NSString *)binaryOperator;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

@interface AssignmentOperator : ASTNode
- (id) initWithRightOperand: (ASTNode *)rightOperand;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

@interface TernaryOperator : ASTNode
- (id) initWithTrueOperand: (ASTNode *)trueOperand
              falseOperand: (ASTNode *)falseOperand;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

@interface PrefixOperator : ASTNode
- (id) init: (ASTNode *)operand
           : (NSString *)prefixOperator;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

@interface PostfixOperator : ASTNode
- (id) init: (ASTNode *)operand
           : (NSString *)prefixOperator;
// - (NSString *) toCode
// - (GenericType *) inferType;
@end

///
@interface BinaryExpression: ASTNode

@property (nonatomic, retain) ASTNode *current;
@property (nonatomic, retain) BinaryExpression *next;

- (id) initWithExpression: (ASTNode *)expression;
- (id) initWithExpression: (ASTNode *)expression
                     next: (BinaryExpression *)next;
- (void) leftAndRightTypeToCodeLeft: (ParenthesizedExpression *)left
                              right: (ParenthesizedExpression *)right;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface NamedExpression: ASTNode
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) ASTNode *expr;
- (id) initWithName: (NSString *)name
               expr: (ASTNode *)expr;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface TypeExpression: ASTNode
@property (nonatomic, retain) GenericType *linkedType;
- (id) initWithLinkedType: (GenericType *)linkedType;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface ExpressionList : ASTNode

@property (nonatomic, retain) ASTNode *current;
@property (nonatomic, retain) ExpressionList *next;

- (id)initWithExpr: (ASTNode *)expr
              next: (ExpressionList *)next;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface ParenthesizedExpression : ASTNode

@property (nonatomic,retain) ASTNode *expression;
@property (nonatomic,assign) BOOL allowInlineTuple;

- (id) initWithExpression: (ASTNode *)expression;
- (NSString *) toInlineTuple: (ExpressionList *) list;
- (BOOL) isList;
- (NSArray *) toExpressionArray;
- (NSArray *) toTypesArray;
- (NSString *) toTupleInitializer: (NSString *)variableName;
// - (NSString *)toCode;
// - (GenericType *)inferType;

@end

@interface FunctionCallExpression : ASTNode

@property (nonatomic, retain) ASTNode *function;
@property (nonatomic, retain) ParenthesizedExpression *parenthesized;

- (id) initWithFunction: (ASTNode *)function
          parenthesized: (ParenthesizedExpression *)parenthesized;

// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface VariableDeclaration: ASTNode

@property (nonatomic, retain) ExpressionList *initializer;
@property (nonatomic, assign) BOOL exportVariables;

- (id) initWithInitializer: (ExpressionList *)initializer;
- (void) exportSymbols: (ASTNode *)expression;

// - (NSString *) toCode;
@end

@interface ArrayLiteral: ASTNode

@property (nonatomic, retain) ASTNode *items;

- (id) initWithItems: (ASTNode *)items;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface DictionaryLiteral : ASTNode

@property (nonatomic, retain) ASTNode *pairs;

- (id) initWithPairs: (ASTNode *)pairs;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end


@interface DictionaryItem: ASTNode

@property (nonatomic, retain) ASTNode *key;
@property (nonatomic, retain) ASTNode *value;

- (id) initWithKey: (ASTNode *)key value: (ASTNode *)value;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end


@interface FunctionParameter : ASTNode
@property (nonatomic, assign) BOOL inoutVal;
@property (nonatomic, assign) BOOL letVal;
@property (nonatomic, assign) BOOL hashVal;
@property (nonatomic, retain) NSString *external;
@property (nonatomic, retain) NSString *local;
@property (nonatomic, retain) ASTNode *defVal;

- (id) initWithInoutVal: (BOOL)inoutVal
                 letVal: (BOOL)letVal
                hashVal: (BOOL)hashVal
               external: (NSString *)external
                  local: (NSString *)local
                 defVal: (ASTNode *)defVal;

// - (NSString *)toCode;
// - (GenericType *)inferType;
@end


@interface FunctionDeclaration : ASTNode
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) ASTNode *signature;
@property (nonatomic, retain) ASTNode *body;

- (id) initWithName: (NSString *)name
          signature: (ASTNode *)signature
               body: (ASTNode *)body;

// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

/*** Statements ***/

@interface WhileStatement : ASTNode
@property (nonatomic, retain) ASTNode *whileCondition;
@property (nonatomic, retain) ASTNode *codeBlock;

- (id)initWithWhileCondition: (ASTNode *)whileCondition
                   codeBlock: (ASTNode *)codeBlock;
// - (NSString *)toCode;
@end


@interface LabelStatement : ASTNode
@property (nonatomic, retain) NSString *labelName;
@property (nonatomic, retain) ASTNode *loop;

- (id) initWithLabelName: (NSString *)labelName
                    loop: (ASTNode *)loop;
// - (NSString *)toCode;
@end

@interface BreakStatement : ASTNode
@property (nonatomic, retain) NSString *labelName;

- (id) initWithLabelId: (NSString *)labelName;
// - (NSString *)toCode;
@end

@interface ReturnStatement : ASTNode
@property (nonatomic, retain) ASTNode *returnExpr;

- (id) initWithReturnExpr:  (ASTNode *)returnExpr;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

        
@interface OptionalChainExprStatement : ASTNode
@property (nonatomic, retain) ASTNode *optChainExpr;

- (id) initWithOptChainExpr:  (ASTNode *)optChainExpr;
// - (NSString *)toCode;
// - (GenericType *)inferType;
@end

@interface IfStatement : ASTNode
@property (nonatomic, retain) ASTNode *ifCondition;
@property (nonatomic, retain) ASTNode *body;
@property (nonatomic, retain) ASTNode *elseClause;

- (id) initWithIfCondition: (ASTNode *)ifCondition
                      body: (ASTNode *)body
                elseClause: (ASTNode *)elseClause;

// - (NSString *)toCode;
@end

@interface ImportStatement : ASTNode
@property (nonatomic, retain) NSString *path;

- (id) initWithPath: (NSString *)path;
// - (NSString *)toCode;
@end
        
@interface StatementNode : ASTNode
@property (nonatomic, retain) ASTNode *statement;

- (id) initWithStatement: (ASTNode *)statement;
// - (NSString *)toCode;
@end

@interface DeclarationStatement : ASTNode
@property (nonatomic, retain) ASTNode *declaration;

- (id) initWithDeclaration: (ASTNode *)declaration;
// - (NSString *)toCode;
@end

@interface StatementsNode : ASTNode
@property (nonatomic, retain) ASTNode *current;
@property (nonatomic, retain) ASTNode *next;
@property (nonatomic, assign) BOOL firstStatement;

- (id) initWithCurrent: (ASTNode *)current;
- (id) initWithCurrent: (ASTNode *)current
                  next: (StatementsNode *)next;

// - (NSString *)toCode;
- (NSInteger) getStatementsCount;
@end
        

        




