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
import Combine

class VLCPlayerViewController: UIHostingController<VLCPlayerViewController.VLCPlayerView>, MvvmViewControllerProtocol {
    var viewModel: VLCPlayerViewModel
    private var disposables: [AnyCancellable] = []

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

        viewModel.$showOverlay.sink { [weak self] value in
            self?.navigationController?.setNavigationBarHidden(!value, animated: true)
        }.store(in: &disposables)
    }

    struct VLCPlayerView: View {
        @ObservedObject var viewModel: VLCPlayerViewModel
        @State var isPlaying: Bool = false
        @State var currentPlaybackTime: TimeInterval = 0
        @State var mediaTimeDuration: TimeInterval = 60 * 6
        @Namespace private var glassNamespace

        var body: some View {
            ZStack(alignment: .bottom) {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            viewModel.showOverlay.toggle()
                        }
                    }

                VLCPlayerViewRepresentable(url: viewModel.url,
                                           isPlaying: $isPlaying,
                                           mediaTimeDuration: $mediaTimeDuration,
                                           currentPlaybackTime: $currentPlaybackTime)
                    .ignoresSafeArea()

                ZStack {
                    CompatibilityGlassContainer(spacing: 24) {
                        if viewModel.showOverlay {
                            overlayButtons
                                .transition(.opacity.combined(with: .scale(scale: 0.96)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .ignoresSafeArea()

                    CompatibilityGlassContainer(spacing: 24) {
                        if viewModel.showOverlay {
                            TimelineView(mediaLengthTime: mediaTimeDuration, currentPlaybackTime: $currentPlaybackTime)
                                .padding()
                                .compatibilityGlassID("timeline", in: glassNamespace)
                                .compatibilityGlassTransition()
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        private var overlayButtons: some View {
            HStack(spacing: 32) {
                PlayerButton(size: .small, imageName: "10.arrow.trianglehead.counterclockwise") {
                    currentPlaybackTime -= 10
                }
                .compatibilityGlassID("backward", in: glassNamespace)

                PlayerButton(size: .big, imageName: isPlaying ? "pause.fill" : "play.fill") {
                    isPlaying.toggle()
                }
                .compatibilityGlassID("playPause", in: glassNamespace)

                PlayerButton(size: .small, imageName: "10.arrow.trianglehead.clockwise") {
                    currentPlaybackTime += 10
                }
                .compatibilityGlassID("forward", in: glassNamespace)
            }
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

                button
                    .compatibilityGlassEffect()
                    .compatibilityGlassTransition()
            }
        }
    }
}

struct VLCPlayerViewRepresentable: UIViewRepresentable {
    var url: URL
    @Binding var isPlaying: Bool
    @Binding var mediaTimeDuration: TimeInterval
    @Binding var currentPlaybackTime: TimeInterval

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        guard let media = VLCMedia(url: url) else { return view }
        context.coordinator.mediaPlayer.drawable = view
        context.coordinator.mediaPlayer.media = media

        // Preparse
        Task {
            let timeout: Int32 = 1_000
            media.parse(options: .parseLocal, timeout: timeout)
            let deadline = Date().addingTimeInterval(TimeInterval(timeout) / 1_000)
            while !media.parsedStatus.isTerminal, Date() < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }
            let initialDuration = Double(media.length.intValue) / 1000
            context.coordinator.updateMediaTimeDuration(initialDuration)
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self

        let mediaPlayer = context.coordinator.mediaPlayer
        if isPlaying {
            if !mediaPlayer.isPlaying {
                mediaPlayer.play()
            }
        } else if mediaPlayer.isPlaying {
            mediaPlayer.pause()
        }

        let duration = max(mediaTimeDuration, 0)
        let clampedPlaybackTime = min(max(currentPlaybackTime, 0), duration)
        if mediaPlayer.isSeekable,
           abs(context.coordinator.lastKnownPlaybackTime - clampedPlaybackTime) > 0.25 {
            context.coordinator.lastKnownPlaybackTime = clampedPlaybackTime
            mediaPlayer.time = VLCTime(number: NSNumber(value: Int(clampedPlaybackTime * 1000)))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VLCMediaPlayerDelegate {
        var parent: VLCPlayerViewRepresentable
        let mediaPlayer = VLCMediaPlayer()

        var lastKnownPlaybackTime: TimeInterval = 0

        init(parent: VLCPlayerViewRepresentable) {
            self.parent = parent
            super.init()
            mediaPlayer.delegate = self
            mediaPlayer.timeChangeUpdateInterval = 0.25
            mediaPlayer.minimalTimePeriod = 250_000
        }

        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            let newPlaybackTime = max(TimeInterval(mediaPlayer.time.value?.doubleValue ?? 0) / 1000, 0)
            lastKnownPlaybackTime = newPlaybackTime
            let parent = parent

            DispatchQueue.main.async {
                if abs(parent.currentPlaybackTime - newPlaybackTime) > 0.05 {
                    parent.currentPlaybackTime = newPlaybackTime
                }
            }
        }

        func mediaPlayerLengthChanged(_ length: Int64) {
            let duration = TimeInterval(length) / 1000
            updateMediaTimeDuration(duration)
        }

        func updateMediaTimeDuration(_ duration: TimeInterval) {
            let parent = parent

            DispatchQueue.main.async {
                if parent.mediaTimeDuration != duration {
                    parent.mediaTimeDuration = duration
                }
            }
        }
    }
}

#Preview {
    UINavigationController(rootViewController: VLCPlayerViewController(viewModel: .init(with: URL(string: "ttest.com")!)))
            .asView
            .ignoresSafeArea()
}
