#import <Foundation/Foundation.h>

@interface PodClass2: NSObject
@end

@implementation PodClass2

+ (void)logSomeLocalizedText {
    // In ObjC, the only NSLocalizedString* macro that can take a default value
    // also requires you to provide _everything_, including explicit bundle and table name :/
    NSString *podString5 = NSLocalizedStringWithDefaultValue(@"pod.key5", @"PodStrings", [NSBundle mainBundle],
                                                             @"pod value 5\n"
                                                             @"with multiple lines.",
                                                             @"Duplicate declaration of Pod key 5 between ObjC and Swift,"
                                                             @"and with a comment even spanning multiple lines!"
                                                             );
    NSString *podString6 = NSLocalizedString(@"pod.key6.%1@d", @"Pod key 6, no value, with key containing placeholder.");
    NSString *podString7 = NSLocalizedStringFromTable(@"pod.key7", @"PodStrings", @"Pod key 7, no value, custom table");
    NSString *podString8 = NSLocalizedStringWithDefaultValue(@"pod.key8", nil, [NSBundle mainBundle],
                                                             @"podvalue8, %1$@.",
                                                             @"Pod key 8, with value containing placeholder.");
    NSString *podString9 = NSLocalizedStringFromTableInBundle(@"pod.key9", @"PodStrings", [NSBundle bundleForClass: [PodClass2 self]],
                                                             "Pod key 9, with custom bundle and table.");

    NSLog(@"%@ %@ %@ %@ %@", podString5, podString6, podString7, podString8, podString9);
}

@end
