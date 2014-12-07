#import "AST.h"

@implementation DeclarationStatement

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
