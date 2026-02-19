import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "AccentColor" asset catalog color resource.
    static let accent = DeveloperToolsSupport.ColorResource(name: "AccentColor", bundle: resourceBundle)

    /// The "Base200Color" asset catalog color resource.
    static let base200 = DeveloperToolsSupport.ColorResource(name: "Base200Color", bundle: resourceBundle)

    /// The "Base300Color" asset catalog color resource.
    static let base300 = DeveloperToolsSupport.ColorResource(name: "Base300Color", bundle: resourceBundle)

    /// The "BaseColor" asset catalog color resource.
    static let base = DeveloperToolsSupport.ColorResource(name: "BaseColor", bundle: resourceBundle)

    /// The "MyPrimaryColor" asset catalog color resource.
    static let myPrimary = DeveloperToolsSupport.ColorResource(name: "MyPrimaryColor", bundle: resourceBundle)

    /// The "MySecondaryColor" asset catalog color resource.
    static let mySecondary = DeveloperToolsSupport.ColorResource(name: "MySecondaryColor", bundle: resourceBundle)

    /// The "NeutralColor" asset catalog color resource.
    static let neutral = DeveloperToolsSupport.ColorResource(name: "NeutralColor", bundle: resourceBundle)

    /// The "TextColor" asset catalog color resource.
    static let text = DeveloperToolsSupport.ColorResource(name: "TextColor", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "AccentColor" asset catalog color.
    static var accent: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "Base200Color" asset catalog color.
    static var base200: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .base200)
#else
        .init()
#endif
    }

    /// The "Base300Color" asset catalog color.
    static var base300: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .base300)
#else
        .init()
#endif
    }

    /// The "BaseColor" asset catalog color.
    static var base: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .base)
#else
        .init()
#endif
    }

    /// The "MyPrimaryColor" asset catalog color.
    static var myPrimary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .myPrimary)
#else
        .init()
#endif
    }

    /// The "MySecondaryColor" asset catalog color.
    static var mySecondary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .mySecondary)
#else
        .init()
#endif
    }

    /// The "NeutralColor" asset catalog color.
    static var neutral: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .neutral)
#else
        .init()
#endif
    }

    /// The "TextColor" asset catalog color.
    static var text: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .text)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "AccentColor" asset catalog color.
    static var accent: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .accent)
#else
        .init()
#endif
    }

    /// The "Base200Color" asset catalog color.
    static var base200: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .base200)
#else
        .init()
#endif
    }

    /// The "Base300Color" asset catalog color.
    static var base300: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .base300)
#else
        .init()
#endif
    }

    /// The "BaseColor" asset catalog color.
    static var base: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .base)
#else
        .init()
#endif
    }

    /// The "MyPrimaryColor" asset catalog color.
    static var myPrimary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .myPrimary)
#else
        .init()
#endif
    }

    /// The "MySecondaryColor" asset catalog color.
    static var mySecondary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .mySecondary)
#else
        .init()
#endif
    }

    /// The "NeutralColor" asset catalog color.
    static var neutral: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .neutral)
#else
        .init()
#endif
    }

    /// The "TextColor" asset catalog color.
    static var text: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .text)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "Base200Color" asset catalog color.
    static var base200: SwiftUI.Color { .init(.base200) }

    /// The "Base300Color" asset catalog color.
    static var base300: SwiftUI.Color { .init(.base300) }

    /// The "BaseColor" asset catalog color.
    static var base: SwiftUI.Color { .init(.base) }

    /// The "MyPrimaryColor" asset catalog color.
    static var myPrimary: SwiftUI.Color { .init(.myPrimary) }

    /// The "MySecondaryColor" asset catalog color.
    static var mySecondary: SwiftUI.Color { .init(.mySecondary) }

    /// The "NeutralColor" asset catalog color.
    static var neutral: SwiftUI.Color { .init(.neutral) }

    /// The "TextColor" asset catalog color.
    static var text: SwiftUI.Color { .init(.text) }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "AccentColor" asset catalog color.
    static var accent: SwiftUI.Color { .init(.accent) }

    /// The "Base200Color" asset catalog color.
    static var base200: SwiftUI.Color { .init(.base200) }

    /// The "Base300Color" asset catalog color.
    static var base300: SwiftUI.Color { .init(.base300) }

    /// The "BaseColor" asset catalog color.
    static var base: SwiftUI.Color { .init(.base) }

    /// The "MyPrimaryColor" asset catalog color.
    static var myPrimary: SwiftUI.Color { .init(.myPrimary) }

    /// The "MySecondaryColor" asset catalog color.
    static var mySecondary: SwiftUI.Color { .init(.mySecondary) }

    /// The "NeutralColor" asset catalog color.
    static var neutral: SwiftUI.Color { .init(.neutral) }

    /// The "TextColor" asset catalog color.
    static var text: SwiftUI.Color { .init(.text) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

