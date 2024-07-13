import SwiftUI

/// This view populates its content's ``layoutMarginsInsets`` and ``readableContentInsets``.
public struct WithLayoutMargins<Content>: View where Content: View {
  let content: (EdgeInsets) -> Content

  /// Initialize a ``WithLayoutMargins`` view, populating its content's ``layoutMarginsInsets``
  ///  and ``readableContentInsets``.
  ///
  /// - Parameter content: A closure that builds a `Content` view from the layout
  /// margins provided in the form of an `EdgeInsets` argument.
  public init(@ViewBuilder content: @escaping (EdgeInsets) -> Content) {
    self.content = content
  }

  /// Initialize a ``WithLayoutMargins`` view, populating  its content's ``layoutMarginsInsets``
  /// and ``readableContentInsets``.
  ///
  /// - Parameter content: A closure that builds a `Content` view.
  public init(@ViewBuilder content: @escaping () -> Content) {
    self.content = { _ in content() }
  }

  public var body: some View {
    InsetContent(content: content)
      .measureLayoutMargins()
  }

  private struct InsetContent: View {
    let content: (EdgeInsets) -> Content
    @Environment(\.layoutMarginsInsets) var layoutMarginsInsets
    var body: some View {
      content(layoutMarginsInsets)
    }
  }
}

/// This view makes its content `View` fit the readable content width.
///
/// - Note: This modifier is equivalent to calling ``.fitToReadableContentWidth()`` on
/// the content view.
@available(
  iOS, deprecated: 9999.0, message: "Use the `.fitToReadableContentWidth` modifier instead."
)
@available(
  macOS, deprecated: 9999.0, message: "Use the `.fitToReadableContentWidth` modifier instead."
)
@available(
  tvOS, deprecated: 9999.0, message: "Use the `.fitToReadableContentWidth` modifier instead."
)
@available(
  watchOS, deprecated: 9999.0, message: "Use the `.fitToReadableContentWidth` modifier instead."
)
public struct FitReadableContentWidth<Content>: View where Content: View {
  let alignment: Alignment
  let content: Content

  /// Initialize some ``FitReadableContentWidth`` view.
  ///
  /// - Parameters:
  ///   - alignment: The `Alignment` to use when `content`  is smaller than
  /// the readable content width.
  ///   - content:  The view that should fit the readable content width.
  public init(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content
  ) {
    self.alignment = alignment
    self.content = content()
  }

  public var body: some View {
    self.modifier(FitLayoutGuidesWidth(alignment: alignment, kind: .readableContent))
  }
}

/// This view makes its content `View` fit the layout margins guide width.
///
/// - Note: This modifier is equivalent to calling ``.fitToLayoutMarginsWidth()`` on
/// the content view.
@available(iOS, deprecated: 9999.0, message: "Use the `.fitToLayoutMarginsWidth` modifier instead.")
@available(
  macOS, deprecated: 9999.0, message: "Use the `.fitToLayoutMarginsWidth` modifier instead."
)
@available(
  tvOS, deprecated: 9999.0, message: "Use the `.fitToLayoutMarginsWidth` modifier instead."
)
@available(
  watchOS, deprecated: 9999.0, message: "Use the `.fitToLayoutMarginsWidth` modifier instead."
)
public struct FitLayoutMarginsWidth<Content>: View where Content: View {
  let alignment: Alignment
  let content: Content

  /// Initialize some ``FitLayoutMarginsWidth`` view.
  ///
  /// - Parameters:
  ///   - alignment: The `Alignment` to use when `content`  is smaller than
  /// the layout margins guide width.
  ///   - content:  The view that should fit the layout margins guide width.
  public init(
    alignment: Alignment = .center,
    @ViewBuilder content: () -> Content
  ) {
    self.alignment = alignment
    self.content = content()
  }

  public var body: some View {
    self.modifier(FitLayoutGuidesWidth(alignment: alignment, kind: .layoutMargins))
  }
}

internal struct FitLayoutGuidesWidth: ViewModifier {
  enum Kind {
    case layoutMargins
    case readableContent
  }

  let alignment: Alignment
  let kind: Kind

  func body(content: Content) -> some View {
    switch kind {
    case .layoutMargins:
      content.modifier(InsetLayoutMargins(alignment: alignment))
        .measureLayoutMargins()
    case .readableContent:
      content.modifier(InsetReadableContent(alignment: alignment))
        .measureLayoutMargins()
    }
  }

  private struct InsetReadableContent: ViewModifier {
    let alignment: Alignment
    @Environment(\.readableContentInsets) var readableContentInsets
    func body(content: Content) -> some View {
      content
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.leading, readableContentInsets.leading)
        .padding(.trailing, readableContentInsets.trailing)
    }
  }

  private struct InsetLayoutMargins: ViewModifier {
    let alignment: Alignment
    @Environment(\.layoutMarginsInsets) var layoutMarginsInsets
    func body(content: Content) -> some View {
      content
        .frame(maxWidth: .infinity, alignment: alignment)
        .padding(.leading, layoutMarginsInsets.leading)
        .padding(.trailing, layoutMarginsInsets.trailing)
    }
  }
}

extension View {
  /// Use this modifier to make the view fit the readable content width.
  ///
  /// - Parameter alignment: The `Alignment` to use when the view is smaller than
  /// the readable content width.
  /// - Note: You don't have to wrap this view inside a ``WithLayoutMargins`` view.
  /// - Note: This modifier is equivalent to wrapping the view inside a
  /// ``FitReadableContentWidth`` view.
  public func fitToReadableContentWidth(alignment: Alignment = .center) -> some View {
    self.modifier(FitLayoutGuidesWidth(alignment: alignment, kind: .readableContent))
  }

  /// Use this modifier to make the view fit the layout margins guide width.
  ///
  /// - Parameter alignment: The `Alignment` to use when the view is smaller than
  /// the readable content width.
  /// - Note: You don't have to wrap this view inside a ``WithLayoutMargins`` view.
  /// - Note: This modifier is equivalent to wrapping the view inside a
  /// ``FitLayoutMarginsWidth`` view.
  public func fitToLayoutMarginsWidth(alignment: Alignment = .center) -> some View {
    self.modifier(FitLayoutGuidesWidth(alignment: alignment, kind: .layoutMargins))
  }
  /// Use this modifier to populate the ``layoutMarginsInsets`` and ``readableContentInsets``
  /// for the target view.
  ///
  /// - Note: You don't have to wrap this view inside a ``WithLayoutMargins`` view.
  public func measureLayoutMargins() -> some View {
    self.modifier(LayoutGuidesModifier())
  }
}

private struct LayoutMarginsGuidesKey: EnvironmentKey {
  static var defaultValue: EdgeInsets { .init() }
}

private struct ReadableContentGuidesKey: EnvironmentKey {
  static var defaultValue: EdgeInsets { .init() }
}

extension EnvironmentValues {
  /// The `EdgeInsets` corresponding to the layout margins of the nearest
  /// ``WithLayoutMargins``'s content.
  public var layoutMarginsInsets: EdgeInsets {
    get { self[LayoutMarginsGuidesKey.self] }
    set { self[LayoutMarginsGuidesKey.self] = newValue }
  }

  /// The `EdgeInsets` corresponding to the readable content of the nearest
  /// ``WithLayoutMargins``'s content.
  public var readableContentInsets: EdgeInsets {
    get { self[ReadableContentGuidesKey.self] }
    set { self[ReadableContentGuidesKey.self] = newValue }
  }
}

struct LayoutGuidesModifier: ViewModifier {
  @State var layoutMarginsInsets: EdgeInsets = .init()
  @State var readableContentInsets: EdgeInsets = .init()

  func body(content: Content) -> some View {
    content
    #if os(iOS) || os(tvOS)
      .environment(\.layoutMarginsInsets, layoutMarginsInsets)
      .environment(\.readableContentInsets, readableContentInsets)
      .background(
        LayoutGuides(
          onLayoutMarginsGuideChange: {
            layoutMarginsInsets = $0
          },
          onReadableContentGuideChange: {
            readableContentInsets = $0
          })
      )
    #endif
  }
}

#if os(iOS) || os(tvOS)
  import UIKit
  struct LayoutGuides: UIViewRepresentable {
    let onLayoutMarginsGuideChange: (EdgeInsets) -> Void
    let onReadableContentGuideChange: (EdgeInsets) -> Void

    func makeUIView(context: Context) -> LayoutGuidesView {
      let uiView = LayoutGuidesView()
      uiView.onLayoutMarginsGuideChange = onLayoutMarginsGuideChange
      uiView.onReadableContentGuideChange = onReadableContentGuideChange
      return uiView
    }

    func updateUIView(_ uiView: LayoutGuidesView, context: Context) {
      uiView.onLayoutMarginsGuideChange = onLayoutMarginsGuideChange
      uiView.onReadableContentGuideChange = onReadableContentGuideChange
    }

    final class LayoutGuidesView: UIView {
      var onLayoutMarginsGuideChange: (EdgeInsets) -> Void = { _ in }
      var onReadableContentGuideChange: (EdgeInsets) -> Void = { _ in }

      override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        updateLayoutMargins()
        updateReadableContent()
      }

      override func layoutSubviews() {
        super.layoutSubviews()
        updateReadableContent()
      }

      // `layoutSubviews` doesn't seem late enough to retrieve an up-to-date `readableContentGuide`
      // in some cases, like when toggling the sidebar in a NavigationSplitView on iPad.
      // It seems that observing the `frame` is enough to fix this edge case, but a better
      // heuristic would be preferable.
      override var frame: CGRect {
        didSet {
          self.updateReadableContent()
        }
      }

      override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.layoutDirection != previousTraitCollection?.layoutDirection {
          updateReadableContent()
        }
      }

      var previousLayoutMargins: EdgeInsets? = nil
      func updateLayoutMargins() {
        let edgeInsets = EdgeInsets(
          top: directionalLayoutMargins.top,
          leading: directionalLayoutMargins.leading,
          bottom: directionalLayoutMargins.bottom,
          trailing: directionalLayoutMargins.trailing
        )
        guard previousLayoutMargins != edgeInsets else { return }
        onLayoutMarginsGuideChange(edgeInsets)
        previousLayoutMargins = edgeInsets
      }

      var previousReadableContentGuide: EdgeInsets? = nil
      func updateReadableContent() {
        let isRightToLeft = traitCollection.layoutDirection == .rightToLeft
        let layoutFrame = readableContentGuide.layoutFrame

        let readableContentInsets =
          UIEdgeInsets(
            top: layoutFrame.minY - bounds.minY,
            left: layoutFrame.minX - bounds.minX,
            bottom: -(layoutFrame.maxY - bounds.maxY),
            right: -(layoutFrame.maxX - bounds.maxX)
          )
        let edgeInsets = EdgeInsets(
          top: readableContentInsets.top,
          leading: isRightToLeft ? readableContentInsets.right : readableContentInsets.left,
          bottom: readableContentInsets.bottom,
          trailing: isRightToLeft ? readableContentInsets.left : readableContentInsets.right
        )
        guard previousReadableContentGuide != edgeInsets else { return }
        onReadableContentGuideChange(edgeInsets)
        previousReadableContentGuide = edgeInsets
      }
    }
  }
#endif

#if DEBUG
  struct Cell: View {
    var value: String
    var body: some View {
      ZStack {
        Text(value)
          .frame(maxWidth: .infinity)
      }
      .background(Color.blue.opacity(0.3))
      .border(Color.blue)  // This view fits in readable content width
      .fitToReadableContentWidth()
      .border(Color.red)  // This view is unconstrained
    }
  }

  struct ListTest: View {
    var body: some View {
      List {
        ForEach(0..<30) {
          Cell(value: "\($0)")
        }
      }
    }
  }

  struct ScrollViewTest: View {
    var body: some View {
      ScrollView {
        VStack(spacing: 0) {
          ForEach(0..<30) {
            Cell(value: "\($0)")
          }
        }
      }
    }
  }

  #if os(iOS)
    @available(iOS 16.0, *)
    struct SwiftUILayoutGuides_Previews: PreviewProvider {
      static func sample<Content>(_ title: String, _ content: () -> Content) -> some View
      where Content: View {
        VStack(alignment: .leading) {
          Text(title)
            .font(Font.system(size: 20, weight: .bold))
            .padding()
          content()
        }
        .border(Color.primary, width: 2)
      }

      static var previews: some View {
        NavigationSplitView {
          VStack(spacing: 0) {
            sample("ScrollView") { ScrollViewTest() }
            sample("List.plain") { ListTest().listStyle(.plain) }
            #if os(iOS) || os(tvOS)
              sample("List.grouped") { ListTest().listStyle(.grouped) }
              sample("List.insetGrouped") { ListTest().listStyle(.insetGrouped) }
            #endif
          }
        } detail: {
          VStack(spacing: 0) {
            sample("ScrollView") { ScrollViewTest() }
            sample("List.plain") { ListTest().listStyle(.plain) }
            #if os(iOS) || os(tvOS)
              sample("List.grouped") { ListTest().listStyle(.grouped) }
              sample("List.insetGrouped") { ListTest().listStyle(.insetGrouped) }
            #endif
          }
        }
        .previewInterfaceOrientation(.landscapeRight)
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (11-inch) (4th generation)"))
      }
    }
  #endif
#endif
