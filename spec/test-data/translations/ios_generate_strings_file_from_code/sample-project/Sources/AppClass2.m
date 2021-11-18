#import <Foundation/Foundation.h>

@interface AppClass2: NSObject
@end

@implementation AppClass2

+ (void)logSomeLocalizedText {
    // In ObjC, the only NSLocalizedString* macro that can take a default value
    // also requires you to provide _everything_, including explicit bundle and table name :/
    NSString *appString5 = NSLocalizedStringWithDefaultValue(@"app.key5", @"AppStrings", [NSBundle mainBundle],
                                                             @"app value 5\nwith multiple lines, and different value than in Swift",
                                                             @"Duplicate declaration of App key 5 between ObjC and Swift,"
                                                             @"and with a comment even spanning multiple lines!"
                                                             );
    NSString *appString6 = NSLocalizedString(@"app.key6.%1@d", @"App key 6, no value, with key containing placeholder.");
    NSString *appString7 = NSLocalizedStringFromTable(@"app.key7", @"AppStrings", @"App key 7, no value, custom table");
    NSString *appString8 = NSLocalizedStringWithDefaultValue(@"app.key8", nil, [NSBundle mainBundle],
                                                             @"appvalue8, %1$@.",
                                                             @"App key 8, with value containing placeholder.");
    NSString *appString9 = NSLocalizedStringFromTableInBundle(@"app.key9", @"AppStrings", [NSBundle bundleForClass: [PodClass2 self]],
                                                             "App key 9, with custom bundle and table.");

    NSLog(@"%@ %@ %@ %@ %@", appString5, appString6, appString7, appString8, appString9);
}

@end
