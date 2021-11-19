// This class is only used to test that calls to
// NSLocalizedString("key", comment: "context for translators");
// and similar are properly parsed by our action, but .h files are not.

@interface AppClass2: NSObject
+ (void)logSomeLocalizedText;
@end
