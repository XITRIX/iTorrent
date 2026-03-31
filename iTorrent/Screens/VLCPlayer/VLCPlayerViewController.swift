//
//  VLCPlayerViewController.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 21.03.2026.
//

import Combine
import MvvmFoundation
import SwiftUI
import UIKit
import VLCKit
import AVKit

class VLCPlayerViewController: UIHostingController<VLCPlayerViewController.Body>, MvvmViewControllerProtocol {
    var viewModel: VLCPlayerViewModel
    private var disposeBag = DisposeBag() // [AnyCancellable] = []

    required init(viewModel: VLCPlayerViewModel) {
        self.viewModel = viewModel
        super.init(rootView: Body(viewModel: viewModel))
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

//        let routePickerView = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 24, height: 24))
//        routePickerView.prioritizesVideoDevices = true
//        routePickerView.tintColor = .label
//        routePickerView.activeTintColor = .systemBlue
//        let item = UIBarButtonItem(customView: routePickerView)
//        if #available(iOS 26.0, *) {
//            item.style = Air.shared.connected ? .prominent : .plain
//        }
//
//        navigationItem.leftBarButtonItem = item

        disposeBag.bind {
//            Air.shared.$connected.sink { aired in
//                if #available(iOS 26.0, *) {
//                    item.style = aired ? .prominent : .plain
//                }
//            }
            Air.shared.$connected.combineLatest(viewModel.$showOverlay)
                .sink { [weak self] aired, value in
                    let show = aired || value
                    self?.navigationController?.setNavigationBarHidden(!show, animated: true)
                }
        }
    }

    struct Body: View {
        @ObservedObject var viewModel: VLCPlayerViewModel

        var body: some View {
            VLCPlayerView(viewModel: viewModel)
                .environmentObject(Air.shared)
        }
    }

    struct VLCPlayerView: View {
        @EnvironmentObject var airPlay: Air
        @ObservedObject var viewModel: VLCPlayerViewModel
        @State var isPlaying: Bool = true
        @State var currentPlaybackTime: TimeInterval = 0
        @State var mediaTimeDuration: TimeInterval = 60 * 6
        @State var isSeeking: Bool = false
        @Namespace private var glassNamespace

        var showOverlay: Bool {
            viewModel.showOverlay || airPlay.connected
        }

        var body: some View {
            ZStack(alignment: .bottom) {
                Color(showOverlay ? .systemGroupedBackground : .black)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            viewModel.showOverlay.toggle()
                        }
                    }

                VLCPlayerViewRepresentable(url: viewModel.url,
                                           isPlaying: isPlaying,
                                           mediaTimeDuration: $mediaTimeDuration,
                                           currentPlaybackTime: $currentPlaybackTime,
                                           isSeeking: isSeeking)
                    .ignoresSafeArea()

                ZStack {
                    CompatibilityGlassContainer(spacing: 24) {
                        VStack {
                            if airPlay.connected {
                                Label("Displaying via AirPlay", systemImage: "airplayvideo")
                                    .font(.title3.weight(.semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                            }
                            if showOverlay {
                                overlayButtons
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .ignoresSafeArea()

                    CompatibilityGlassContainer(spacing: 24) {
                        if showOverlay {
                            TimelineView(mediaLengthTime: mediaTimeDuration, currentPlaybackTime: $currentPlaybackTime, isSeeking: $isSeeking, availability: viewModel.segmentedProgress)
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
            var action: () -> Void

            var body: some View {
                let button = Button {
                    action()
                } label: {
                    let image = Image(systemName: imageName)
                        .frame(width: size.view, height: size.view)
                        .font(.system(size: size.font, weight: .medium))
                        .foregroundStyle(Color.white)

                    if #available(iOS 17.0, *) {
                        image.contentTransition(.symbolEffect(.replace.downUp, options: .speed(3)))
                    } else {
                        image
                    }
                }

                button
                    .compatibilityGlassEffect(isClear: true, interactive: true)
                    .compatibilityGlassTransition()
            }
        }
    }
}

struct VLCPlayerViewRepresentable: UIViewRepresentable {
    let url: URL
    let isPlaying: Bool
    @Binding var mediaTimeDuration: TimeInterval
    @Binding var currentPlaybackTime: TimeInterval
    let isSeeking: Bool

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false

        let drawable = UIView()
        drawable.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        drawable.frame = view.bounds
        view.addSubview(drawable)

        Air.play(drawable)

        context.coordinator.drawableView = drawable
        context.coordinator.attachDrawable(drawable)

        // Preparse
        guard let media = VLCMedia(url: url) else { return view }
        Task { @MainActor in
            let timeout: Int32 = 1000
            media.parse(options: .parseLocal, timeout: timeout)
            let deadline = Date().addingTimeInterval(TimeInterval(timeout) / 1000)
            while !media.parsedStatus.isTerminal, Date() < deadline {
                try? await Task.sleep(for: .milliseconds(50))
            }
            let initialDuration = Double(media.length.intValue) / 1000
            context.coordinator.updateMediaTimeDuration(initialDuration)
            context.coordinator.mediaPlayer.play()
            try await Task.sleep(for: .seconds(0.2))
            context.coordinator.mediaPlayer.pause()
        }
        context.coordinator.mediaPlayer.media = media

        return view
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        Air.stop()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        context.coordinator.parent = self

        let mediaPlayer = context.coordinator.mediaPlayer
        if isPlaying {
            if !mediaPlayer.isPlaying {
                mediaPlayer.play()
            }
        } else if mediaPlayer.isPlaying, !context.coordinator.isPerformingPausedSeek {
            mediaPlayer.pause()
        }

        let duration = max(mediaTimeDuration, 0)
        let clampedPlaybackTime = min(max(currentPlaybackTime, 0), duration)

        let stoppedSeeking = context.coordinator.lastIsSeeking && !isSeeking
        context.coordinator.lastIsSeeking = isSeeking

        if mediaPlayer.isSeekable, !stoppedSeeking {
            let time = VLCTime(number: NSNumber(value: Int(clampedPlaybackTime * 1000)))
            if abs(time.intValue - mediaPlayer.time.intValue) > 1000 {
                context.coordinator.seek(to: time, shouldPlay: isPlaying)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, VLCMediaPlayerDelegate, @unchecked Sendable {
        var parent: VLCPlayerViewRepresentable
        let mediaPlayer = VLCMediaPlayer()
        var drawableView: UIView?
        var lastIsSeeking: Bool = false
        var isPerformingPausedSeek: Bool = false
        private var notificationObservers: [NSObjectProtocol] = []
        private var pausedSeekTask: Task<Void, Never>?

        init(parent: VLCPlayerViewRepresentable) {
            self.parent = parent
            super.init()
            mediaPlayer.delegate = self
            mediaPlayer.timeChangeUpdateInterval = 0.25
            mediaPlayer.minimalTimePeriod = 250000
            observeApplicationLifecycle()
        }

        deinit {
            pausedSeekTask?.cancel()
            notificationObservers.forEach(NotificationCenter.default.removeObserver)
        }

        func attachDrawable(_ view: UIView) {
            drawableView = view
            mediaPlayer.drawable = view
        }

        func seek(to time: VLCTime, shouldPlay: Bool) {
            pausedSeekTask?.cancel()
            let targetTime = time.intValue

            if shouldPlay {
                mediaPlayer.time = VLCTime(number: NSNumber(value: targetTime))
                return
            }

            pausedSeekTask = Task { @MainActor [weak self] in
                guard let self else { return }

                self.isPerformingPausedSeek = true
                defer {
                    self.isPerformingPausedSeek = false
                    self.pausedSeekTask = nil
                }

                self.mediaPlayer.play()
                try? await Task.sleep(for: .milliseconds(80))
                guard !Task.isCancelled else { return }

                self.mediaPlayer.time = VLCTime(number: NSNumber(value: targetTime))
                try? await Task.sleep(for: .milliseconds(80))
                guard !Task.isCancelled else { return }

                self.mediaPlayer.pause()
            }
        }

        private func observeApplicationLifecycle() {
            let center = NotificationCenter.default

            notificationObservers.append(center.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main)
            { [weak self] _ in
                Task {
                    try await self?.restoreVideoOutput()
                }
            })
        }

        @MainActor
        private func restoreVideoOutput() async throws {
            guard !mediaPlayer.isPlaying else { return }

            let parent = parent
            let playbackTime = parent.currentPlaybackTime

            mediaPlayer.stop()
            mediaPlayer.play()

            try await Task.sleep(for: .seconds(0.1))
            mediaPlayer.time = VLCTime(number: NSNumber(value: Int(playbackTime * 1000)))

            mediaPlayer.pause()
        }

        func mediaPlayerTimeChanged(_ aNotification: Notification) {
            guard !parent.isSeeking else { return }

            let newPlaybackTime = max(TimeInterval(mediaPlayer.time.value?.doubleValue ?? 0) / 1000, 0)
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
    UINavigationController(rootViewController: VLCPlayerViewController(viewModel: .init(with: .init(url: URL(string: "ttest.com")!, torrentPair: nil))))
        .asView
        .ignoresSafeArea()
}
