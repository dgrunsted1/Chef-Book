#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"bwt.Chef-Book";

/// The "AccentColor" asset catalog color resource.
static NSString * const ACColorNameAccentColor AC_SWIFT_PRIVATE = @"AccentColor";

/// The "Base200Color" asset catalog color resource.
static NSString * const ACColorNameBase200Color AC_SWIFT_PRIVATE = @"Base200Color";

/// The "Base300Color" asset catalog color resource.
static NSString * const ACColorNameBase300Color AC_SWIFT_PRIVATE = @"Base300Color";

/// The "BaseColor" asset catalog color resource.
static NSString * const ACColorNameBaseColor AC_SWIFT_PRIVATE = @"BaseColor";

/// The "MyPrimaryColor" asset catalog color resource.
static NSString * const ACColorNameMyPrimaryColor AC_SWIFT_PRIVATE = @"MyPrimaryColor";

/// The "MySecondaryColor" asset catalog color resource.
static NSString * const ACColorNameMySecondaryColor AC_SWIFT_PRIVATE = @"MySecondaryColor";

/// The "NeutralColor" asset catalog color resource.
static NSString * const ACColorNameNeutralColor AC_SWIFT_PRIVATE = @"NeutralColor";

/// The "TextColor" asset catalog color resource.
static NSString * const ACColorNameTextColor AC_SWIFT_PRIVATE = @"TextColor";

#undef AC_SWIFT_PRIVATE
