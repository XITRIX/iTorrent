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
import AVKit
import MediaPlayer
import SwiftVLC

struct TracksMenuView: View {
    let tracks: [Track]
    @Binding var selectedTrack: Track?
    let title: LocalizedStringKey
    let systemImage: String

    var body: some View {
        Menu {
            Section {
                ForEach(tracks) { track in
                    Toggle(track.title, isOn: .init(get: {
                        selectedTrack?.id == track.id
                    }, set: { value in
                        guard value else { return }
                        selectedTrack = track
                    }))
                }
            } header: {
                Text(title)
            }
        } label: {
            Image(systemName: systemImage)
        }
        .menuOrder(.fixed)
        .labelStyle(.iconOnly)
        .imageScale(.medium)
        .accessibilityLabel(title)
    }
}

struct PlaybackRateMenuView: View {
    let rates: [Float]
    @Binding var selectedRate: Float

    var body: some View {
        Menu {
            Section {
                ForEach(rates, id: \.self) { rate in
                    Toggle(rate.formattedRate, isOn: .init(get: {
                        selectedRate == rate
                    }, set: { value in
                        guard value else { return }
                        selectedRate = rate
                    }))
                }
            } header: {
                Text("Playback Speed")
            }
        } label: {
            Image(systemName: "speedometer")
        }
        .menuOrder(.fixed)
        .labelStyle(.iconOnly)
        .imageScale(.medium)
        .accessibilityLabel("Playback Speed")
    }
}

private extension Float {
    var formattedRate: String {
        if self == floor(self) {
            return "\(Int(self))x"
        }

        return String(format: "%.2gx", self)
    }
}

private extension Track {
    var title: String {
        [trackDescription ?? name, (localizedLanguageName ?? language).map { "[\($0)]" }]
            .compactMap { $0 }
            .joined(separator: " - ")
    }

    var localizedLanguageName: String? {
        guard let language else { return nil }
        return Locale(identifier: "en").localizedString(forLanguageCode: language)
    }
}

class VLCPlayerViewController: BaseHostingController<VLCPlayerViewController.Body>, MvvmViewControllerProtocol {
    var viewModel: VLCPlayerViewModel
    private var disposeBag = DisposeBag() // [AnyCancellable] = []

    override var useMarqueeLabel: Bool { true }

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

        title = viewModel.url.lastPathComponent
        navigationItem.largeTitleDisplayMode = .never

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}

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
            #if !os(visionOS)
            Air.shared.$connected.combineLatest(viewModel.$showOverlay)
                .sink { [weak self] aired, value in
                    let show = aired || value
                    self?.navigationController?.setNavigationBarHidden(!show, animated: true)
                }
            #else
            viewModel.$showOverlay
                .sink { [weak self] show in
                    self?.navigationController?.setNavigationBarHidden(!show, animated: true)
                }
            #endif
        }
    }

    struct Body: View {
        @ObservedObject var viewModel: VLCPlayerViewModel

        var body: some View {
            VLCPlayerView(viewModel: viewModel)
#if !os(visionOS)
                .environmentObject(Air.shared)
#endif
        }
    }

    struct VLCPlayerView: View {
#if !os(visionOS)
        @EnvironmentObject var airPlay: Air
#endif
        @ObservedObject var viewModel: VLCPlayerViewModel
        @State private var player = Player()
        @State private var currentPlaybackTime: TimeInterval = 0
        @State private var mediaTimeDuration: TimeInterval = 60 * 6
        @State private var isSeeking: Bool = false
        @State private var audioTracks: [Track] = []
        @State private var textTracks: [Track] = []
        @State private var selectedAudioTrack: Track?
        @State private var selectedTextTrack: Track?
        @State private var playbackRate: Float = 1
        @State private var didStartPlayback = false
        @State private var isRestoringPlayback = false
        @State private var pendingPausedSeekRefreshTime: TimeInterval?
        @State private var remoteCommands = RemoteCommandController()
        @Namespace private var glassNamespace
        private let playbackRates: [Float] = [0.5, 0.75, 1, 1.25, 1.5, 2]
        private let nowPlayingCenter = MPNowPlayingInfoCenter.default()

        var showOverlay: Bool {
#if !os(visionOS)
            viewModel.showOverlay || airPlay.connected
#else
            viewModel.showOverlay
#endif
        }

        private var showsPlayingState: Bool {
            isRestoringPlayback ? false : player.isPlaying
        }

        var body: some View {
            WithPerceptionTracking {
                content
            }
            .task {
                await preparePlaybackIfNeeded()
            }
            .task {
                await observePlayerEvents()
            }
            .onAppear {
                configureRemoteCommandCenter()
            }
            .onDisappear {
                tearDownPlayback()
            }
            .onChange(of: playbackRate) { newRate in
                setPlaybackRate(newRate)
            }
            .onChange(of: selectedAudioTrack) { track in
                player.selectedAudioTrack = track
            }
            .onChange(of: selectedTextTrack) { track in
                player.selectedSubtitleTrack = track
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                restorePlaybackAfterForeground()
            }
        }

        private var content: some View {
            ZStack(alignment: .bottom) {
                Color(showOverlay ? .systemGroupedBackground : .black)
                    .ignoresSafeArea()

                videoOutput
                    .ignoresSafeArea()

                if showOverlay {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                }

                Color.clear
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            viewModel.showOverlay.toggle()
                        }
                    }

                ZStack {
                    CompatibilityGlassContainer(spacing: 24) {
                        VStack {
#if !os(visionOS)
                            if airPlay.connected {
                                Label("Displaying via AirPlay", systemImage: "airplayvideo")
                                    .font(.title3.weight(.semibold))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 14)
                            }
#endif
                            if showOverlay {
                                overlayButtons
                                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .ignoresSafeArea()

                    CompatibilityGlassContainer(spacing: 16) {
                        if showOverlay {
                            VStack(alignment: .trailing, spacing: 16) {
                                controlsBar

                                TimelineView(
                                    mediaLengthTime: mediaTimeDuration,
                                    currentPlaybackTime: $currentPlaybackTime,
                                    isSeeking: $isSeeking,
                                    availability: viewModel.segmentedProgress,
                                    onScrubChanged: { time in
                                        seek(to: time, fast: true)
                                    },
                                    onScrubEnded: { time in
                                        seek(to: time, fast: false)
                                    }
                                )
                                .compatibilityGlassID("timeline", in: glassNamespace)
                                    .compatibilityGlassTransition()
                            }
                            .padding()
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }

        @ViewBuilder
        private var videoOutput: some View {
#if !os(visionOS)
            VideoView(player, onSurfaceReady: Air.play)
#else
            VideoView(player)
#endif
        }

        private var controlsBar: some View {
            HStack {
                HStack(spacing: 16) {
                    PlaybackRateMenuView(
                        rates: playbackRates,
                        selectedRate: $playbackRate
                    )
                }
//                .padding(.horizontal)
                .frame(width: 44, height: 44)
                .compatibilityGlassEffect(interactive: true)
                .compatibilityGlassID("controls", in: glassNamespace)
                .compatibilityGlassTransition()

                Spacer()

                HStack(spacing: 16) {
                    TracksMenuView(
                        tracks: audioTracks,
                        selectedTrack: $selectedAudioTrack,
                        title: "Audio",
                        systemImage: "waveform"
                    )

                    TracksMenuView(
                        tracks: textTracks,
                        selectedTrack: $selectedTextTrack,
                        title: "Subtitles",
                        systemImage: "text.alignleft"
                    )
                }
                .padding(.horizontal)
                .frame(height: 44)
                .compatibilityGlassEffect(interactive: true)
                .compatibilityGlassID("controls", in: glassNamespace)
                .compatibilityGlassTransition()
            }
            .tint(Color.secondary)
            .font(.title3.weight(.semibold))
        }

        private var overlayButtons: some View {
            HStack(spacing: 32) {
                PlayerButton(size: .small, imageName: "10.arrow.trianglehead.counterclockwise") {
                    skip(by: -10)
                }
                .compatibilityGlassID("backward", in: glassNamespace)

                PlayerButton(size: .big, imageName: showsPlayingState ? "pause.fill" : "play.fill") {
                    guard !isRestoringPlayback else { return }
                    togglePlayback()
                }
                .compatibilityGlassID("playPause", in: glassNamespace)

                PlayerButton(size: .small, imageName: "10.arrow.trianglehead.clockwise") {
                    skip(by: 10)
                }
                .compatibilityGlassID("forward", in: glassNamespace)
            }
        }

        private func preparePlaybackIfNeeded() async {
            guard !didStartPlayback else { return }
            didStartPlayback = true
            configureNowPlayingMetadata()

            do {
                let media = try Media(url: viewModel.url)
                if let metadata = try? await media.parse(timeout: .seconds(1)), let duration = metadata.duration {
                    updateMediaTimeDuration(duration.timeInterval)
                    updateNowPlaying(duration: duration.timeInterval)
                }
                try Task.checkCancellation()
                try player.play(media)
                setPlaybackRate(playbackRate)
                syncTracksFromPlayer()
                updateNowPlayingPlaybackState()
            } catch is CancellationError {
                player.stop()
            } catch {
                didStartPlayback = false
            }
        }

        private func observePlayerEvents() async {
            for await event in player.events {
                switch event {
                case .timeChanged(let time):
                    guard !isSeeking else { continue }
                    let newPlaybackTime = max(time.timeInterval, 0)
                    if abs(currentPlaybackTime - newPlaybackTime) > 0.05 {
                        currentPlaybackTime = newPlaybackTime
                    }
                    updateNowPlaying()
                case .lengthChanged(let duration):
                    updateMediaTimeDuration(duration.timeInterval)
                    updateNowPlaying(duration: duration.timeInterval)
                case .tracksChanged, .mediaChanged:
                    syncTracksFromPlayer()
                case .stateChanged:
                    updateNowPlayingPlaybackState()
                case .endReached:
                    currentPlaybackTime = mediaTimeDuration
                    updateNowPlayingPlaybackState()
                default:
                    break
                }
            }
        }

        private func configureRemoteCommandCenter() {
            remoteCommands.configure(
                supportedPlaybackRates: playbackRates,
                play: {
                    try? player.play()
                    refreshVideoAfterPausedSeekIfNeeded()
                    updateNowPlayingPlaybackState()
                },
                pause: {
                    player.pause()
                    updateNowPlayingPlaybackState()
                },
                toggle: {
                    togglePlayback()
                },
                seek: { time in
                    seek(to: time)
                },
                skip: { interval in
                    skip(by: interval)
                },
                rate: { rate in
                    playbackRate = rate
                    setPlaybackRate(rate)
                }
            )
        }

        private func tearDownPlayback() {
#if !os(visionOS)
            Air.stop()
#endif
            player.stop()
            remoteCommands.tearDown()
        }

        private func syncTracksFromPlayer() {
            audioTracks = player.audioTracks
            textTracks = player.subtitleTracks

            if let selected = player.selectedAudioTrack {
                selectedAudioTrack = selected
            } else if selectedAudioTrack == nil {
                selectedAudioTrack = audioTracks.first
            }

            if let selected = player.selectedSubtitleTrack {
                selectedTextTrack = selected
            } else if selectedTextTrack == nil {
                selectedTextTrack = textTracks.first
            }
        }

        private func setPlaybackRate(_ rate: Float) {
            try? player.setPlaybackRate(PlaybackRate(rate))
            updateNowPlayingPlaybackState()
        }

        private func togglePlayback() {
            player.togglePlayPause()
            refreshVideoAfterPausedSeekIfNeeded()
            updateNowPlayingPlaybackState()
        }

        private func refreshVideoAfterPausedSeekIfNeeded() {
            guard let time = pendingPausedSeekRefreshTime else { return }

            Task { @MainActor in
                for _ in 0..<5 {
                    try? await Task.sleep(for: .milliseconds(80))
                    guard pendingPausedSeekRefreshTime == time else { return }
                    guard player.isPlaying else { continue }
                    pendingPausedSeekRefreshTime = nil
                    seek(to: time)
                    return
                }
            }
        }

        private func seek(to time: TimeInterval, fast: Bool = false) {
            let duration = max(mediaTimeDuration, 0)
            let clampedTime = min(max(time, 0), duration)
            let wasPlaying = player.isPlaying
            currentPlaybackTime = clampedTime

            guard player.isSeekable || player.duration != nil else {
                updateNowPlaying()
                return
            }

            try? player.seek(to: .milliseconds(Int64((clampedTime * 1_000).rounded())), fast: fast)
            if wasPlaying {
                pendingPausedSeekRefreshTime = nil
            } else if !fast {
                pendingPausedSeekRefreshTime = clampedTime
            }
            updateNowPlaying()
        }

        private func skip(by interval: TimeInterval) {
            seek(to: currentPlaybackTime + interval)
        }

        private func restorePlaybackAfterForeground() {
            guard didStartPlayback, !player.isPlaying, !isRestoringPlayback else { return }
            let playbackTime = currentPlaybackTime
            isRestoringPlayback = true
            Task { @MainActor in
                defer {
                    isRestoringPlayback = false
                    updateNowPlayingPlaybackState()
                }
                await player.stopAndWait()
                try? player.play()
                try? await Task.sleep(for: .milliseconds(200))
                seek(to: playbackTime)
                await scrubMinimallyForRestoredVideoFrame(around: playbackTime)
                player.pause()
                currentPlaybackTime = playbackTime
            }
        }

        private func scrubMinimallyForRestoredVideoFrame(around time: TimeInterval) async {
            guard let scrubTime = minimalScrubTime(around: time) else { return }
            try? await Task.sleep(for: .milliseconds(80))
            seek(to: scrubTime, fast: true)
            try? await Task.sleep(for: .milliseconds(80))
            seek(to: time)
        }

        private func minimalScrubTime(around time: TimeInterval) -> TimeInterval? {
            let duration = max(mediaTimeDuration, 0)
            guard duration > 0 else { return nil }

            let offset: TimeInterval = 0.05
            if time + offset <= duration {
                return time + offset
            }
            if time - offset >= 0 {
                return time - offset
            }
            return nil
        }

        private func configureNowPlayingMetadata() {
            var info = nowPlayingCenter.nowPlayingInfo ?? [:]
            info[MPMediaItemPropertyTitle] = viewModel.url.deletingPathExtension().lastPathComponent
            info[MPMediaItemPropertyPlaybackDuration] = max(mediaTimeDuration, 0)
            info[MPNowPlayingInfoPropertyMediaType] = MPNowPlayingInfoMediaType.video.rawValue

            let artworkImage = UIImage.icon(forFileURL: viewModel.url, size: 512)
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artworkImage.size) { _ in artworkImage }

            nowPlayingCenter.nowPlayingInfo = info
            updateNowPlayingPlaybackState()
        }

        private func updateNowPlaying(duration: TimeInterval? = nil) {
            var info = nowPlayingCenter.nowPlayingInfo ?? [:]
            if let duration {
                info[MPMediaItemPropertyPlaybackDuration] = max(duration, 0)
            }
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = max(currentPlaybackTime, 0)
            info[MPNowPlayingInfoPropertyPlaybackRate] = player.isPlaying ? Double(playbackRate) : 0
            nowPlayingCenter.nowPlayingInfo = info
        }

        private func updateNowPlayingPlaybackState() {
            nowPlayingCenter.playbackState = player.isPlaying ? .playing : .paused
            updateNowPlaying()
        }

        private func updateMediaTimeDuration(_ duration: TimeInterval) {
            guard mediaTimeDuration != duration else { return }
            mediaTimeDuration = duration
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

private final class RemoteCommandController {
    private var remoteCommandTargets: [Any] = []
    private let remoteCommandCenter = MPRemoteCommandCenter.shared()
    private let nowPlayingCenter = MPNowPlayingInfoCenter.default()

    func configure(
        supportedPlaybackRates: [Float],
        play: @escaping @MainActor @Sendable () -> Void,
        pause: @escaping @MainActor @Sendable () -> Void,
        toggle: @escaping @MainActor @Sendable () -> Void,
        seek: @escaping @MainActor @Sendable (TimeInterval) -> Void,
        skip: @escaping @MainActor @Sendable (TimeInterval) -> Void,
        rate: @escaping @MainActor @Sendable (Float) -> Void
    ) {
        guard remoteCommandTargets.isEmpty else { return }

        let playTarget = remoteCommandCenter.playCommand.addTarget { _ in
            Self.perform(play)
        }
        let pauseTarget = remoteCommandCenter.pauseCommand.addTarget { _ in
            Self.perform(pause)
        }
        let toggleTarget = remoteCommandCenter.togglePlayPauseCommand.addTarget { _ in
            Self.perform(toggle)
        }
        let seekTarget = remoteCommandCenter.changePlaybackPositionCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let positionTime = event.positionTime
            return Self.perform { seek(positionTime) }
        }
        let skipForwardTarget = remoteCommandCenter.skipForwardCommand.addTarget { _ in
            Self.perform { skip(10) }
        }
        let skipBackwardTarget = remoteCommandCenter.skipBackwardCommand.addTarget { _ in
            Self.perform { skip(-10) }
        }
        let rateTarget = remoteCommandCenter.changePlaybackRateCommand.addTarget { event in
            guard let event = event as? MPChangePlaybackRateCommandEvent else { return .commandFailed }
            let playbackRate = Float(event.playbackRate)
            return Self.perform { rate(playbackRate) }
        }

        remoteCommandTargets = [playTarget, pauseTarget, toggleTarget, seekTarget, skipForwardTarget, skipBackwardTarget, rateTarget]
        remoteCommandCenter.playCommand.isEnabled = true
        remoteCommandCenter.pauseCommand.isEnabled = true
        remoteCommandCenter.togglePlayPauseCommand.isEnabled = true
        remoteCommandCenter.changePlaybackPositionCommand.isEnabled = true
        remoteCommandCenter.skipForwardCommand.isEnabled = true
        remoteCommandCenter.skipForwardCommand.preferredIntervals = [10]
        remoteCommandCenter.skipBackwardCommand.isEnabled = true
        remoteCommandCenter.skipBackwardCommand.preferredIntervals = [10]
        remoteCommandCenter.changePlaybackRateCommand.isEnabled = true
        remoteCommandCenter.changePlaybackRateCommand.supportedPlaybackRates = supportedPlaybackRates.map(NSNumber.init(value:))
    }

    func tearDown() {
        remoteCommandTargets.forEach { target in
            remoteCommandCenter.playCommand.removeTarget(target)
            remoteCommandCenter.pauseCommand.removeTarget(target)
            remoteCommandCenter.togglePlayPauseCommand.removeTarget(target)
            remoteCommandCenter.changePlaybackPositionCommand.removeTarget(target)
            remoteCommandCenter.skipForwardCommand.removeTarget(target)
            remoteCommandCenter.skipBackwardCommand.removeTarget(target)
            remoteCommandCenter.changePlaybackRateCommand.removeTarget(target)
        }
        remoteCommandTargets.removeAll()
        nowPlayingCenter.nowPlayingInfo = nil
        nowPlayingCenter.playbackState = .stopped
    }

    private static func perform(_ action: @escaping @MainActor @Sendable () -> Void) -> MPRemoteCommandHandlerStatus {
        Task { @MainActor in
            action()
        }
        return .success
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(milliseconds) / 1_000
    }
}

#Preview {
    UINavigationController(rootViewController: VLCPlayerViewController(viewModel: .init(with: .init(url: URL(string: "ttest.com")!, torrentPair: nil))))
        .asView
        .ignoresSafeArea()
}
