//
//  TimelineView.swift
//  iTorrent
//
//  Created by Даниил Виноградов on 26.03.2026.
//

import SwiftUI

struct TimelineView: View {
    let mediaLengthTime: TimeInterval
    @Binding var currentPlaybackTime: TimeInterval
    @Binding var isSeeking: Bool
    let availability: [Double]?
    @GestureState private var dragStartTime: TimeInterval?

    var body: some View {
        GeometryReader { geometry in
            timelineContent(width: geometry.size.width)
        }
        .frame(height: 44)
    }
}

private extension TimelineView {
    @ViewBuilder
    func timelineContent(width: Double) -> some View {
        let content = HStack {
            Text(played)
            AVProgressView(value: progress, availability: availability)
            Text("-\(timeLeft)")
        }
        .foregroundStyle(.secondary)
        .font(.footnote).bold()
        .padding()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .updating($dragStartTime) { _, state, _ in
                    state = state ?? currentPlaybackTime
                }
                .onChanged { gesture in
                    isSeeking = true
                    let startTime = dragStartTime ?? currentPlaybackTime
                    currentPlaybackTime = playbackTime(
                        startTime: startTime,
                        translationX: gesture.translation.width,
                        width: width
                    )
                }
                .onEnded { _ in
                    isSeeking = false
                }
        )
        .compatibilityGlassEffect(interactive: true)
        .compatibilityGlassTransition()

        if #available(iOS 16.1, *) {
            content.fontDesign(.monospaced)
        } else {
            content
        }
    }

    var progress: Double {
        guard mediaLengthTime > 0 else { return 0 }
        return min(max(currentPlaybackTime / mediaLengthTime, 0), 1)
    }

    func playbackTime(startTime: TimeInterval, translationX: Double, width: Double) -> TimeInterval {
        guard width > 0, mediaLengthTime > 0 else { return currentPlaybackTime }
        let secondsPerPoint = mediaLengthTime / width
        return min(max(startTime + translationX * secondsPerPoint, 0), mediaLengthTime)
    }

    var played: String {
        formattedTime(currentPlaybackTime, maxTime: mediaLengthTime)
    }

    var timeLeft: String {
        formattedTime(max(mediaLengthTime - currentPlaybackTime, 0), maxTime: mediaLengthTime)
    }

    func formattedTime(_ time: TimeInterval, maxTime: TimeInterval) -> String {
        let totalSeconds = max(Int(time.rounded(.down)), 0)
        let maxTotalSeconds = max(Int(maxTime.rounded(.down)), 0)

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        let maxHours = maxTotalSeconds / 3600
        let maxMinutes = maxTotalSeconds / 60

        let paddedSeconds = String(format: "%02d", seconds)

        if maxHours > 0 {
            let hourWidth = max(String(maxHours).count, 1)
            let paddedHours = String(format: "%0*d", hourWidth, hours)
            let paddedMinutes = String(format: "%02d", minutes)
            return "\(paddedHours):\(paddedMinutes):\(paddedSeconds)"
        } else {
            let minuteWidth = max(String(maxMinutes).count, 1)
            let paddedMinutes = String(format: "%0*d", minuteWidth, minutes)
            return "\(paddedMinutes):\(paddedSeconds)"
        }
    }
}

struct AVProgressView: View {
    var value: Double
    var height: Double = 8
    var knobSize: Double = 0
    var availability: [Double]?

    var body: some View {
        let clampedValue = min(max(value, 0), 1)
        let availableColor = Color(.label).opacity(0.28)
        let unavailableColor = Color.red.opacity(0.28)

        GeometryReader { geometry in
            let availableWidth = max(geometry.size.width - knobSize, 0)
            let progressWidth = availableWidth * clampedValue

            ZStack(alignment: .leading) {
                availabilityBackground(
                    availableColor: availableColor,
                    unavailableColor: unavailableColor
                )
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

    @ViewBuilder
    func availabilityBackground(availableColor: Color, unavailableColor: Color) -> some View {
        if let availability, !availability.isEmpty {
            HStack(spacing: 0) {
                ForEach(Array(availability.enumerated()), id: \.offset) { _, piece in
                    Rectangle()
                        .fill(piece == 1 ? availableColor : unavailableColor)
                }
            }
        } else {
            Capsule()
                .fill(availableColor)
        }
    }
}
