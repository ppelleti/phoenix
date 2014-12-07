#import "AST.h"

@implementation StatementNode

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
    return [NSString stringWithFormat:@"%@;",[self.statement toCode]];
}

@end
