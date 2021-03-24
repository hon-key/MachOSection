#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef struct MachOSectionItem {
    void *value;
    bool func;
    bool autorelease;
    NSString *tag;
}MachOSectionItem;

// Value Definition
#define MACH_O_SECTION_VALUE_DEFINITION(KEY,VALUE,TAG) \
__attribute__((used,section("__DATA" "," #KEY))) static const MachOSectionItem KEY##_v = {(void *)VALUE,false,false,TAG};

// Function Definition
#define MACH_O_SECTION_FUNCTION_DEFINITION_F(KEY,AUTORELEASE,TAG) \
static void KEY(void); \ 
__attribute__((used,section("__DATA" "," #KEY))) static const MachOSectionItem KEY##_f = {(void *)&KEY,true,AUTORELEASE,TAG}; \
static void KEY(void) \

#define MACH_O_SECTION_FUNCTION_DEFINITION(KEY) MACH_O_SECTION_FUNCTION_DEFINITION_F(KEY,false,@"FUNC")

// using mach-o section to execute function or read pre defined value
@interface MachOSection : NSObject

+ (instancetype)new NS_UNAVAILABLE;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)shareInstance;

- (void)executeFunctionsForKey:(NSString *)key;

- (MachOSectionItem *)sectionItemsForKey:(NSString *)key getCount:(NSUInteger *)count;

@end

NS_ASSUME_NONNULL_END
