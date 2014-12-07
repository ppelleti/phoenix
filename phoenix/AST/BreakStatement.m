#import "AST.h"

@implementation BreakStatement

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
