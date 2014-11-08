//
//  cliinput-Bridging-Header.h
//

@class Lexer;
@class ASTNode;
ASTNode* bridge_yyparse(Lexer * lexer, int debug);
const char * bridge_yyerror();