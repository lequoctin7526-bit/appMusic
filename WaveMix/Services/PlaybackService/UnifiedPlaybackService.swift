import Foundation
import SwiftUI
import AVFoundation
import Combine

/// Master playback engine coordinating YouTube WKWebView player, Apple MusicKit,
/// AVPlayer (Licensed Catalog), Lock Screen Now Playing, and Queue management.
@MainActor
public final class UnifiedPlaybackService: ObservableObject, AudioSessionServiceDelegate, MediaRemoteServiceDelegate {
    @Published public private(set) var state: PlaybackState = .idle
    @Published public private(set) var queue: PlaybackQueue = PlaybackQueue()
    @Published public var currentTime: TimeInterval = 0
    @Published public var duration: TimeInterval = 0
    @Published public var isMiniPlayerExpanded: Bool = false
    @Published public var showLicensedMatchSheet: Bool = false

    public let youtubeController: YouTubePlayerController

    private let appleMusicService: AppleMusicService
    private let licensedCatalogService: LicensedCatalogService
    private let audioSessionService: AudioSessionService
    private let nowPlayingService: NowPlayingService
    private let mediaRemoteService: MediaRemoteService
    private let storageService: StorageService

    private var avPlayer: AVPlayer?
    private var timeObserverToken: Any?
    private var cancellables = Set<AnyCancellable>()
    private var isAppInBackground: Bool = false

    public init(
        youtubeController: YouTubePlayerController? = nil,
        appleMusicService: AppleMusicService = AppleMusicService(),
        licensedCatalogService: LicensedCatalogService = LicensedCatalogService(),
        audioSessionService: AudioSessionService = AudioSessionService(),
        nowPlayingService: NowPlayingService = NowPlayingService(),
        mediaRemoteService: MediaRemoteService = MediaRemoteService(),
        storageService: StorageService = StorageService()
    ) {
        self.youtubeController = youtubeController ?? YouTubePlayerController()
        self.appleMusicService = appleMusicService
        self.licensedCatalogService = licensedCatalogService
        self.audioSessionService = audioSessionService
        self.nowPlayingService = nowPlayingService
        self.mediaRemoteService = mediaRemoteService
        self.storageService = storageService

        self.audioSessionService.delegate = self
        self.mediaRemoteService.delegate = self

        setupYouTubeBindings()
        setupLifecycleObservers()
    }

    deinit {
        removeTimeObserver()
    }

    public var currentTrack: MusicTrack? {
        state.currentTrack ?? queue.currentTrack
    }

    public var isPlaying: Bool {
        state.isPlaying
    }

    // MARK: - Playback Commands

    public func play(track: MusicTrack, in tracks: [MusicTrack] = []) {
        var newTracks = tracks.isEmpty ? [track] : tracks
        if !newTracks.contains(where: { $0.id == track.id }) {
            newTracks.insert(track, at: 0)
        }
        let startIndex = newTracks.firstIndex(where: { $0.id == track.id }) ?? 0
        queue.setQueue(tracks: newTracks, startIndex: startIndex)

        loadAndExecute(track: track)
    }

    private func loadAndExecute(track: MusicTrack) {
        // App Store & YouTube Policy: YouTube cannot start or play in background
        if track.provider == .youtube && isAppInBackground {
            state = .waitingForForeground(track: track, reason: "YouTube requires the screen to be active.")
            stopAllPlayers()
            return
        }

        state = .loading(track: track)
        currentTime = 0
        duration = track.duration

        // Record to recently played
        Task {
            try? await storageService.recordPlayback(track: track)
        }

        switch track.provider {
        case .youtube:
            executeYouTubeTrack(track)
        case .appleMusic:
            executeAppleMusicTrack(track)
        case .licensedCatalog, .localLibrary:
            executeLicensedTrack(track)
        }
    }

    private func executeYouTubeTrack(_ track: MusicTrack) {
        // Stop native audio player & disable audio session
        stopNativePlayer()
        audioSessionService.deactivatePlaybackSession()
        nowPlayingService.clear()
        mediaRemoteService.setRemoteCommandsEnabled(false)

        guard let videoID = track.youtubeVideoID ?? track.providerTrackID as String? else {
            state = .failed(error: "Missing YouTube Video ID", track: track)
            return
        }

        youtubeController.loadVideo(videoID: videoID)
        youtubeController.play()
        state = .playing(track: track)
    }

    private func executeAppleMusicTrack(_ track: MusicTrack) {
        // Stop YouTube player
        youtubeController.pause()

        do {
            try audioSessionService.activatePlaybackSession()
            mediaRemoteService.setRemoteCommandsEnabled(true)
            nowPlayingService.updateNowPlaying(track: track, currentTime: 0, isPlaying: true)

            Task {
                do {
                    try await appleMusicService.playTrack(trackID: track.providerTrackID)
                    self.state = .playing(track: track)
                } catch {
                    self.state = .failed(error: "Apple Music playback error: \(error.localizedDescription)", track: track)
                }
            }
        } catch {
            state = .failed(error: "Audio session activation failed", track: track)
        }
    }

    private func executeLicensedTrack(_ track: MusicTrack) {
        youtubeController.pause()

        do {
            try audioSessionService.activatePlaybackSession()
            mediaRemoteService.setRemoteCommandsEnabled(true)

            Task {
                do {
                    let player = try await licensedCatalogService.preparePlayer(for: track)
                    self.avPlayer = player
                    self.attachTimeObserver(for: player, track: track)
                    player.play()
                    self.state = .playing(track: track)
                    self.nowPlayingService.updateNowPlaying(track: track, currentTime: 0, isPlaying: true)
                } catch {
                    self.state = .failed(error: "Licensed playback error: \(error.localizedDescription)", track: track)
                }
            }
        } catch {
            state = .failed(error: "Audio session error: \(error.localizedDescription)", track: track)
        }
    }

    public func togglePlayPause() {
        guard let track = currentTrack else { return }

        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    public func pause() {
        guard let track = currentTrack else { return }

        switch track.provider {
        case .youtube:
            youtubeController.pause()
        case .appleMusic:
            appleMusicService.pause()
        case .licensedCatalog, .localLibrary:
            avPlayer?.pause()
        }

        state = .paused(track: track)
        nowPlayingService.updateNowPlaying(track: track, currentTime: currentTime, isPlaying: false)
    }

    public func resume() {
        guard let track = currentTrack else { return }

        if track.provider == .youtube && isAppInBackground {
            state = .waitingForForeground(track: track, reason: "Please open WaveMix to resume YouTube playback.")
            return
        }

        switch track.provider {
        case .youtube:
            youtubeController.play()
            state = .playing(track: track)
        case .appleMusic:
            Task {
                try? await appleMusicService.resume()
                self.state = .playing(track: track)
                self.nowPlayingService.updateNowPlaying(track: track, currentTime: self.currentTime, isPlaying: true)
            }
        case .licensedCatalog, .localLibrary:
            avPlayer?.play()
            state = .playing(track: track)
            nowPlayingService.updateNowPlaying(track: track, currentTime: currentTime, isPlaying: true)
        }
    }

    public func next() {
        guard let nextTrack = queue.advanceToNext() else {
            stopAllPlayers()
            state = .stopped
            return
        }
        loadAndExecute(track: nextTrack)
    }

    public func previous() {
        // If current playback > 3 seconds, restart current track
        if currentTime > 3.0 {
            seek(to: 0)
            return
        }

        guard let prevTrack = queue.advanceToPrevious() else {
            seek(to: 0)
            return
        }
        loadAndExecute(track: prevTrack)
    }

    public func seek(to seconds: TimeInterval) {
        currentTime = seconds
        guard let track = currentTrack else { return }

        switch track.provider {
        case .youtube:
            youtubeController.seek(to: seconds)
        case .appleMusic:
            break
        case .licensedCatalog, .localLibrary:
            let cmTime = CMTime(seconds: seconds, preferredTimescale: 600)
            avPlayer?.seek(to: cmTime)
        }

        nowPlayingService.updateNowPlaying(track: track, currentTime: seconds, isPlaying: isPlaying)
    }

    public func toggleShuffle() {
        queue.isShuffled.toggle()
    }

    public func cycleRepeatMode() {
        switch queue.repeatMode {
        case .off:
            queue.repeatMode = .all
        case .all:
            queue.repeatMode = .one
        case .one:
            queue.repeatMode = .off
        }
    }

    public func switchToTrack(track: MusicTrack) {
        queue.append(track: track)
        loadAndExecute(track: track)
    }

    // MARK: - Internal Teardown & Lifecycle

    private func stopAllPlayers() {
        youtubeController.stop()
        stopNativePlayer()
        audioSessionService.deactivatePlaybackSession()
        nowPlayingService.clear()
        mediaRemoteService.setRemoteCommandsEnabled(false)
    }

    private func stopNativePlayer() {
        removeTimeObserver()
        avPlayer?.pause()
        avPlayer = nil
        appleMusicService.stop()
    }

    private func attachTimeObserver(for player: AVPlayer, track: MusicTrack) {
        removeTimeObserver()
        let interval = CMTime(seconds: 0.5, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            self.currentTime = time.seconds
            if let currentItem = player.currentItem, currentItem.duration.isNumeric {
                self.duration = currentItem.duration.seconds
            }
        }
    }

    private func removeTimeObserver() {
        if let token = timeObserverToken {
            avPlayer?.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    private func setupYouTubeBindings() {
        youtubeController.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ytState in
                guard let self = self, let track = self.currentTrack, track.provider == .youtube else { return }
                switch ytState {
                case .playing:
                    self.state = .playing(track: track)
                case .paused:
                    self.state = .paused(track: track)
                case .ended:
                    self.next()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        youtubeController.$currentTime
            .receive(on: DispatchQueue.main)
            .sink { [weak self] time in
                guard let self = self, let track = self.currentTrack, track.provider == .youtube else { return }
                self.currentTime = time
            }
            .store(in: &cancellables)

        youtubeController.$duration
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dur in
                guard let self = self, let track = self.currentTrack, track.provider == .youtube, dur > 0 else { return }
                self.duration = dur
            }
            .store(in: &cancellables)
    }

    private func setupLifecycleObservers() {
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.handleDidEnterBackground()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)
            .sink { [weak self] _ in
                self?.handleWillEnterForeground()
            }
            .store(in: &cancellables)
    }

    private func handleDidEnterBackground() {
        isAppInBackground = true

        // Strict YouTube background enforcement
        if let track = currentTrack, track.provider == .youtube {
            youtubeController.pause()
            state = .waitingForForeground(track: track, reason: "YouTube playback paused while app is in background.")
            nowPlayingService.clear()
            mediaRemoteService.setRemoteCommandsEnabled(false)
        }
    }

    private func handleWillEnterForeground() {
        isAppInBackground = false
    }

    // MARK: - AudioSessionServiceDelegate

    public func audioSessionDidReceiveInterruption(shouldResume: Bool) {
        if shouldResume {
            resume()
        } else {
            pause()
        }
    }

    public func audioSessionDidReceiveRouteChange(reason: AVAudioSession.RouteChangeReason) {
        if reason == .oldDeviceUnavailable {
            pause()
        }
    }

    // MARK: - MediaRemoteServiceDelegate

    public func remotePlay() {
        resume()
    }

    public func remotePause() {
        pause()
    }

    public func remoteNext() {
        next()
    }

    public func remotePrevious() {
        previous()
    }

    public func remoteSeek(to seconds: TimeInterval) {
        seek(to: seconds)
    }
}
