//
//  VLCPlayerViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import SwiftUI
import UIKit
import VLCKit
import MvvmFoundation

class VLCPlayerViewController: UIHostingController<VLCPlayerViewController.VLCPlayerView>, MvvmViewControllerProtocol {
    var viewModel: VLCPlayerViewModel

    required init(viewModel: VLCPlayerViewModel) {
        self.viewModel = viewModel
        super.init(rootView: VLCPlayerView(viewModel: viewModel))
    }

    @available(*, unavailable)
    @MainActor @preconcurrency dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = .init(systemItem: .close, primaryAction: .init { [unowned self] _ in
            dismiss()
        })
    }

    struct VLCPlayerView: View {
        var viewModel: VLCPlayerViewModel
        @State var isPlaying: Bool = false
        @State var progress: Double = 0.2

        var body: some View {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                VLCPlayerViewRepresentable(url: viewModel.url, isPlaying: $isPlaying)
                    .ignoresSafeArea()

                HStack(spacing: 32) {
                    PlayerButton(size: .small, imageName: "10.arrow.trianglehead.counterclockwise") {
                    }

                    PlayerButton(size: .big, imageName: isPlaying ? "pause.fill" : "play.fill") {
                        isPlaying.toggle()
                    }

                    PlayerButton(size: .small, imageName: "10.arrow.trianglehead.clockwise") {
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .ignoresSafeArea()

                TimelineView(progress: $progress)
                    .padding()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        struct PlayerButton: View {
            enum Size {
                case small
                case big

                var view: Double {
                    switch self {
                    case .small:
                        62
                    case .big:
                        92
                    }
                }

                var font: Double {
                    switch self {
                    case .small:
                        32
                    case .big:
                        46
                    }
                }
            }

            var size: Size
            var imageName: String
            var action: () -> ()

            var body: some View {
                let button = Button {
                    action()
                } label: {
                    let image = Image(systemName: imageName)
                        .frame(width: size.view, height: size.view)
                        .font(.system(size: size.font))
                        .foregroundStyle(Color(.label))

                    if #available(iOS 17.0, *) {
                        image.contentTransition(.symbolEffect(.replace.downUp, options: .speed(3)))
                    } else {
                        image
                    }
                }

                if #available(iOS 26.0, *) {
                    button.glassEffect(.clear.interactive())
                } else {
                    button.background(Material.thin)
                }
            }
        }

        struct TimelineView: View {
            @Binding var progress: Double

            var body: some View {
                if #available(iOS 26.0, *) {
                    HStack {
                        Text("0:33")
                        AVProgressView(value: progress)
                        Text("-3:33")
                    }
                    .foregroundStyle(.secondary)
                    .fontDesign(.monospaced)
                    .font(.footnote).bold()
                    .padding()
                    .glassEffect(.clear.interactive())
                }
            }
        }
    }
}

struct AVProgressView: View {
    var value: Double
    var height: Double = 8
    var knobSize: Double = 0

    var body: some View {
        let clampedValue = min(max(value, 0), 1)

        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - knobSize, 0)
            let progressWidth = availableWidth * clampedValue

            ZStack(alignment: .leading) {
                Capsule()
//                    .fill(Color.red.opacity(0.28))
                    .fill(Color(.label).opacity(0.28))
                    .frame(height: height)

                Rectangle()
                    .fill(Color(.label).opacity(0.5))
                    .frame(width: progressWidth + knobSize / 2, height: height)

                Circle()
                    .fill(Color(.label))
                    .frame(width: knobSize, height: knobSize)
                    .offset(x: progressWidth)
            }
            .clipShape(.capsule)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
        .frame(height: 16)
    }
}

struct VLCPlayerViewRepresentable: UIViewRepresentable {
    var url: URL
    @Binding var isPlaying: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        context.coordinator.mediaPlayer.drawable = view
        context.coordinator.mediaPlayer.media = VLCMedia(url: url)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        if isPlaying {
            context.coordinator.mediaPlayer.play()
        } else {
            context.coordinator.mediaPlayer.pause()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {
        let mediaPlayer = VLCMediaPlayer()
    }
}

#Preview {
    UINavigationController(rootViewController: VLCPlayerViewController(viewModel: .init(with: URL(string: "ttest.com")!)))
            .asView
            .ignoresSafeArea()
}
