#import "AST.h"

@implementation ImportStatement

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
