import SwiftUI

/// Asynchronous artwork image loader with smooth placeholder and provider fallback
public struct AsyncArtworkView: View {
    public let url: URL?
    public let provider: MusicProvider
    public var cornerRadius: CGFloat = 8

    public init(url: URL?, provider: MusicProvider, cornerRadius: CGFloat = 8) {
        self.url = url
        self.provider = provider
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        Group {
            if let url = url {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .empty:
                        placeholderView
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        placeholderView
                    @unknown default:
                        placeholderView
                    }
                }
            } else {
                placeholderView
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private var placeholderView: some View {
        ZStack {
            WaveMixColors.surfaceElevated
            Image(systemName: provider.systemIcon)
                .font(.system(size: 20))
                .foregroundColor(provider.brandColor.opacity(0.8))
        }
    }
}

/// Animated waveform visualizer indicating audio streaming activity
public struct WaveformVisualizerView: View {
    public let isPlaying: Bool
    public var barCount: Int = 4

    @State private var phase: CGFloat = 0

    public init(isPlaying: Bool, barCount: Int = 4) {
        self.isPlaying = isPlaying
        self.barCount = barCount
    }

    public var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(WaveMixColors.brandGradient)
                    .frame(width: 3, height: barHeight(for: index))
                    .animation(
                        isPlaying ? Animation.easeInOut(duration: 0.45)
                            .repeatForever()
                            .delay(Double(index) * 0.12) : .default,
                        value: phase
                    )
            }
        }
        .onAppear {
            if isPlaying {
                phase = 1
            }
        }
        .onChange(of: isPlaying) { playing in
            phase = playing ? 1 : 0
        }
    }

    private func barHeight(for index: Int) -> CGFloat {
        if !isPlaying { return 4 }
        let heights: [CGFloat] = [16, 24, 12, 20, 14]
        let base = heights[index % heights.count]
        return phase == 1 ? base : 6
    }
}
