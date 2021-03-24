#import "MachOSection.h"
#import <mach-o/loader.h>
#import <mach-o/getsect.h>
#import <dlfcn.h>

#ifndef __LP64__
#define mach_header mach_header
#else
#define mach_header mach_header_64
#endif

static MachOSection *singleton;

@interface MachOSection () {
  struct mach_header *machHeader;
  NSString *configuration;
}
@end
  
@implementation MachOSection
 
- (instancetype)initForPrivate {
    if (singleton) return singleton;
    if (self = [super init]) {
        Dl_info info;
        configutation = @"";
        dladdr((__bridge const void *)configuration, &info);
        machHeader = (struct mach_header *)info.dli_fbase;
    }
    return self;
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispach_once(&onceToken, ^{
        singleton = [MachOSection alloc] initForPrivate];
    });
    return singleton;
}

- (void)executeFunctionsForKey:(NSString *)key {
    unsigned long byteCount = 0;
    MachOSectionItem *items = (MachOSectionItem *)[self pointersForKey:key getLength:&byteCount];
    NSUinteger itemCount = byteCount / sizeof(MachOSectionItem);
    if (itemCount == 0) {
      return;
    }
    @autoreleasepool {
        for (NSUinteger i = 0; i < itemCount; i++) {
            if (items[i].func) {
                void (*method)(void) = (void (*)(void))items[i].value;
                if (items[i].autorelease) {
                    @autoreleasepool {
                        method()
                    }
                }else {
                    method();
                }
            }
        }
    }
}

- (MachOSectionItem *)sectionItemsForKey:(NSString *)key getCount:(nonnull NSUInteger *)count {
    unsigned long byteCount = 0;
    MachOSectionItem *items = (MachOSectionItem *)[self pointersForKey:key getLength:&byteCount];
    NSUInteger itemCount = byteCount / sizeof(MachOSectionItem);
    if (itemCount == 0) {
        return NULL;
    }
    *count = itemCount;
    return items;
}

- (uint8_t *)pointersForKey:(NSString *)key getLength:(nonnull unsigned long *)byteCount {
    if (self != singleton) {
        return NULL;
    }
    uint8_t *data = getsectiondata(machHeader, "__DATA", key.UTF8String, byteCount);
    return data;
}

@end
