//
//  ContentView.swift
//  PlayingCat
//
//  Created by Andrew Kasilov on 21.04.26.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var levelAudio = LevelCompleteAudioPlayer()
    @State private var eyesLookUp = false
    @State private var showHappyCat = false
    @State private var showSadCat = false
    @State private var isLevelCompleted = false
    @State private var happyResetTask: Task<Void, Never>?
    @State private var sadResetTask: Task<Void, Never>?
    @State private var floatingFruitNames: [String] = []
    @State private var selectionFruitButtons: [String] = []
    @State private var floatingFruitFrames: [String: CGRect] = [:]
    @State private var panelItemFrames: [String: CGRect] = [:]
    @State private var dragOffsets: [String: CGSize] = [:]
    @State private var matchedFruits: Set<String> = []
    @State private var showConfetti = false

    private let topFruits = ["bananaImage", "appleImage", "raspberryImage", "strawberryImage", "kiwiImage"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("bgImage")
                        .resizable()

                    Color.black
                        .opacity(isLevelCompleted ? 0.5 : 0)
                        .ignoresSafeArea()

                    ZStack {
                        Image("kittenBaseImage")
                            .resizable()
                            .scaledToFit()
                            .opacity((showHappyCat || showSadCat || isLevelCompleted) ? 0 : 1)

                        Image("kittenHappyImage")
                            .resizable()
                            .scaledToFit()
                            .opacity(showHappyCat ? 1 : 0)

                        Image("kittenSadImage")
                            .resizable()
                            .scaledToFit()
                            .opacity(showSadCat ? 1 : 0)

                        Image("kittenVictoryImage")
                            .resizable()
                            .scaledToFit()
                            .opacity(isLevelCompleted ? 1 : 0)
                    }
                        .overlay {
                            Image("eyesImage")
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(0.4)
                                .rotation3DEffect(
                                    .degrees(eyesLookUp ? 0 : -35),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: 0
                                )
                                .offset(y: eyesLookUp ? -geometry.size.width * 0.2 : -geometry.size.width * 0.22)
                                .opacity((showHappyCat || showSadCat || isLevelCompleted) ? 0 : 1)
                        }
                        .overlay {
                            Image("eyeLidsImage")
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(0.4)
                                .offset(y: -geometry.size.width * 0.2)
                                .opacity((showHappyCat || showSadCat || isLevelCompleted) ? 0 : 1)
                        }
                        .animation(.easeInOut(duration: 0.3), value: showHappyCat)
                        .animation(.easeInOut(duration: 0.3), value: showSadCat)
                        .animation(.easeInOut(duration: 0.35), value: isLevelCompleted)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                eyesLookUp = true
                            }
                        }
                }
                .ignoresSafeArea(edges: .all)

                VStack(spacing: 0) {
                    if !isLevelCompleted {
                        topControls(size: geometry.size.width * 0.15)
                            .padding(.horizontal, 16)
                            .padding(.top, -16)
                    }

                    if !isLevelCompleted {
                        floatingFruits(size: geometry.size.width * 0.3, fruits: floatingFruitNames)
                    }

                    Spacer(minLength: 0)

                    if isLevelCompleted {
                        levelCompleteControls(size: geometry.size.width * 0.26)
                            .padding(.bottom, 22)
                    } else {
                        selectionPanel(size: geometry.size.width * 0.26)
                            .padding(.bottom, 16)
                    }
                }
                .ignoresSafeArea(edges: .bottom)

                if showConfetti {
                    ConfettiView()
                        .transition(.opacity)
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: "gameArea")
            .onAppear {
                if floatingFruitNames.isEmpty || selectionFruitButtons.isEmpty {
                    setupNewShuffledLevel()
                }
            }
        }
    }

    private func topControls(size: CGFloat) -> some View {
        HStack {
            gameCircleButton(imageName: "pauseButtonImage", size: size)
            Spacer()
            gameCircleButton(imageName: "levelButtonImage", size: size)
        }
    }

    private func floatingFruits(size: CGFloat, fruits: [String]) -> some View {
        HStack {
            if fruits.indices.contains(0) {
                floatingFruitImage(fruit: fruits[0], size: size)
            }

            Spacer()

            if fruits.indices.contains(2) {
                floatingFruitImage(fruit: fruits[2], size: size)
            }
        }
        .padding(.horizontal, 12)
        .overlay {
            if fruits.indices.contains(1) {
                floatingFruitImage(fruit: fruits[1], size: size)
                    .offset(x: 10)
                    .padding(.top, -size / 1.0)
            }
        }
        .onPreferenceChange(FloatingFruitFrameKey.self) { value in
            floatingFruitFrames.merge(value) { _, new in new }
        }
    }

    private func selectionPanel(size: CGFloat) -> some View {
        VStack {
            HStack(spacing: 18) {
                ForEach(Array(selectionFruitButtons.prefix(2)), id: \.self) { fruit in
                    draggablePanelFruit(imageName: fruit, size: size)
                }
            }

            HStack(spacing: 18) {
                ForEach(Array(selectionFruitButtons.dropFirst(2)), id: \.self) { fruit in
                    draggablePanelFruit(imageName: fruit, size: size)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onPreferenceChange(PanelFruitFrameKey.self) { value in
            panelItemFrames.merge(value) { _, new in new }
        }
    }

    private func levelCompleteControls(size: CGFloat) -> some View {
        HStack(spacing: size * 0.3) {
            completionControlButton(imageName: "replayButtonImage", size: size, action: restartCurrentLevel)
            completionControlButton(imageName: "playButtonImage", size: size, action: startNextShuffledLevel)
        }
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func completionControlButton(imageName: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            ZStack {
                Color.white
                    .opacity(0.32)
                    .frame(width: size * 1.34, height: size * 1.34)
                    .mask(
                        Image(imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: size * 1.34, height: size * 1.34)
                    )

                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
            }
        }
        .buttonStyle(.plain)
    }

    private func gameCircleButton(imageName: String, size: CGFloat) -> some View {
        Button {
            // Top controls action placeholder.
        } label: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }

    private func floatingFruitImage(fruit: String, size: CGFloat) -> some View {
        Image(fruit)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size * 1.2)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: FloatingFruitFrameKey.self,
                        value: [fruit: proxy.frame(in: .named("gameArea"))]
                    )
                }
            )
            .overlay(
                Color.white.opacity(matchedFruits.contains(fruit) ? 0 : 0.5)
                       .mask( Image(fruit)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size, height: size * 1.2)))
//            .overlay {
//                if matchedFruits.contains(fruit) {
//                    Image(buttonImageName(for: fruit))
//                        .resizable()
//                        .scaledToFit()
//                        .frame(width: size * 0.45, height: size * 0.45)
//                }
//            }
    }

    private func draggablePanelFruit(imageName: String, size: CGFloat) -> some View {
        let fruitName = fruitName(for: imageName)
        let isMatched = matchedFruits.contains(fruitName)

        return Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .opacity(isMatched ? 0 : 1)
            .allowsHitTesting(!isMatched)
            .offset(dragOffsets[imageName] ?? .zero)
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: PanelFruitFrameKey.self,
                        value: [imageName: proxy.frame(in: .named("gameArea"))]
                    )
                }
            )
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffsets[imageName] = value.translation
                    }
                    .onEnded { value in
                        handleDrop(imageName: imageName, translation: value.translation)
                    }
            )
            .animation(.easeOut(duration: 0.18), value: dragOffsets[imageName] ?? .zero)
            .animation(.easeOut(duration: 0.2), value: isMatched)
    }

    private func handleDrop(imageName: String, translation: CGSize) {
        guard !isLevelCompleted else { return }
        let fruitName = fruitName(for: imageName)
        guard
            let sourceFrame = panelItemFrames[imageName]
        else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                dragOffsets[imageName] = .zero
            }
            return
        }

        let movedFrame = sourceFrame.offsetBy(dx: translation.width, dy: translation.height)
        let draggableArea = movedFrame.width * movedFrame.height
        guard draggableArea > 0 else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                dragOffsets[imageName] = .zero
            }
            return
        }

        let overlapRatios = floatingFruitFrames.mapValues { frame -> CGFloat in
            let overlapRect = movedFrame.intersection(frame)
            let overlapArea = overlapRect.isNull ? 0 : overlapRect.width * overlapRect.height
            return overlapArea / draggableArea
        }

        let maxOverlap = overlapRatios.values.max() ?? 0
        let isDroppedOnAnyFloatingFruit = maxOverlap >= 0.2
        let correctOverlap = overlapRatios[fruitName] ?? 0
        let isCorrectMatch = correctOverlap >= 0.2

        if isCorrectMatch {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                matchedFruits.insert(fruitName)
//                dragOffsets[imageName] = .zero
            }
            triggerHappyCatAnimation()
            if matchedFruits.count == floatingFruitNames.count, !floatingFruitNames.isEmpty {
                completeLevel()
            }
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                dragOffsets[imageName] = .zero
            }
            if isDroppedOnAnyFloatingFruit {
                triggerSadCatAnimation()
            }
        }
    }

    private func completeLevel() {
        happyResetTask?.cancel()
        sadResetTask?.cancel()
        levelAudio.stop()
        withAnimation(.easeInOut(duration: 0.4)) {
            showHappyCat = false
            showSadCat = false
            isLevelCompleted = true
            showConfetti = true
        }

        levelAudio.playLevelCompleteSound(fallbackDuration: 2.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                showConfetti = false
            }
        }
    }

    private func restartCurrentLevel() {
        happyResetTask?.cancel()
        sadResetTask?.cancel()
        levelAudio.stop()
        withAnimation(.easeInOut(duration: 0.35)) {
            showHappyCat = false
            showSadCat = false
            isLevelCompleted = false
            showConfetti = false
            matchedFruits.removeAll()
            dragOffsets.removeAll()
            floatingFruitFrames.removeAll()
            panelItemFrames.removeAll()
        }
    }

    private func startNextShuffledLevel() {
        setupNewShuffledLevel()
        restartCurrentLevel()
    }

    private func setupNewShuffledLevel() {
        let newFloating = Array(topFruits.shuffled().prefix(3))
        let extraFruits = Array(topFruits.filter { !newFloating.contains($0) }.shuffled().prefix(2))
        let newSelectionButtons = (newFloating + extraFruits)
            .map(buttonImageName(for:))
            .shuffled()

        floatingFruitNames = newFloating
        selectionFruitButtons = newSelectionButtons
    }

    private func triggerHappyCatAnimation() {
        sadResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showSadCat = false
        }
        happyResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            showHappyCat = true
        }

        happyResetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showHappyCat = false
                }
            }
        }
    }

    private func triggerSadCatAnimation() {
        happyResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.2)) {
            showHappyCat = false
        }
        sadResetTask?.cancel()
        withAnimation(.easeInOut(duration: 0.25)) {
            showSadCat = true
        }

        sadResetTask = Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            if Task.isCancelled { return }
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.35)) {
                    showSadCat = false
                }
            }
        }
    }

    private func fruitName(for buttonImageName: String) -> String {
        buttonImageName.replacingOccurrences(of: "ButtonImage", with: "Image")
    }

    private func buttonImageName(for fruitName: String) -> String {
        fruitName.replacingOccurrences(of: "Image", with: "ButtonImage")
    }
}

private struct FloatingFruitFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct PanelFruitFrameKey: PreferenceKey {
    static var defaultValue: [String: CGRect] = [:]
    static func reduce(value: inout [String: CGRect], nextValue: () -> [String: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private final class LevelCompleteAudioPlayer: NSObject, AVAudioPlayerDelegate {
    private var player: AVAudioPlayer?
    private var fallbackTask: Task<Void, Never>?
    private var onFinished: (() -> Void)?

    func playLevelCompleteSound(fallbackDuration: Double, onFinished: @escaping () -> Void) {
        stop()
        self.onFinished = onFinished

        guard let (url, ext) = Self.resolveSoundURL() else {
            scheduleFallback(seconds: fallbackDuration)
            return
        }

        do {
            let audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: ext)
            audioPlayer.delegate = self
            audioPlayer.prepareToPlay()
            player = audioPlayer

            if audioPlayer.play() {
                return
            }
            scheduleFallback(seconds: fallbackDuration)
        } catch {
            scheduleFallback(seconds: fallbackDuration)
        }
    }

    func stop() {
        fallbackTask?.cancel()
        fallbackTask = nil
        player?.stop()
        player = nil
        onFinished = nil
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        fallbackTask?.cancel()
        fallbackTask = nil
        self.player = nil
        let callback = onFinished
        onFinished = nil
        callback?()
    }

    private func scheduleFallback(seconds: Double) {
        fallbackTask?.cancel()
        fallbackTask = Task {
            try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            if Task.isCancelled { return }
            await MainActor.run { [weak self] in
                guard let self else { return }
                let callback = self.onFinished
                self.onFinished = nil
                callback?()
            }
        }
    }

    private static func resolveSoundURL() -> (URL, String)? {
        let candidates = ["mp3", "wav", "m4a", "caf", "aiff"]
        for ext in candidates {
            if let url = Bundle.main.url(forResource: "phatphrogstudio-phatphrogstudiocom-victory-fanfare-2-474663", withExtension: ext) {
                return (url, ext)
            }
        }
        return nil
    }
}

private struct ConfettiView: View {
    private let pieces: [ConfettiPiece] = (0..<24).map { _ in ConfettiPiece.random }

    var body: some View {
        GeometryReader { geometry in
            TimelineView(.animation) { timeline in
                let time = timeline.date.timeIntervalSinceReferenceDate
                ZStack {
                    ForEach(Array(pieces.enumerated()), id: \.offset) { _, piece in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(piece.color)
                            .frame(width: piece.size.width, height: piece.size.height)
                            .rotationEffect(.degrees(piece.rotation + time * piece.spinSpeed))
                            .position(
                                x: piece.xRatio * geometry.size.width + sin(time * piece.wobbleSpeed) * piece.wobbleDistance,
                                y: piece.yPosition(time: time, height: geometry.size.height)
                            )
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct ConfettiPiece {
    let xRatio: CGFloat
    let fallDuration: Double
    let delay: Double
    let size: CGSize
    let rotation: Double
    let spinSpeed: Double
    let wobbleDistance: Double
    let wobbleSpeed: Double
    let color: Color

    func yPosition(time: TimeInterval, height: CGFloat) -> CGFloat {
        let cycleTime = max(0.1, time + delay)
        let progress = cycleTime.truncatingRemainder(dividingBy: fallDuration) / fallDuration
        return progress * (height + 80) - 40
    }

    static var random: ConfettiPiece {
        ConfettiPiece(
            xRatio: .random(in: 0.05...0.95),
            fallDuration: .random(in: 2.0...3.8),
            delay: .random(in: 0...2),
            size: CGSize(width: .random(in: 6...12), height: .random(in: 10...18)),
            rotation: .random(in: 0...360),
            spinSpeed: .random(in: 50...180),
            wobbleDistance: .random(in: 6...20),
            wobbleSpeed: .random(in: 1.2...2.6),
            color: [.yellow, .orange, .pink, .mint, .blue, .purple].randomElement() ?? .yellow
        )
    }
}

#Preview {
    ContentView()
}
