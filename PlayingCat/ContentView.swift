//
//  ContentView.swift
//  PlayingCat
//
//  Created by Andrew Kasilov on 21.04.26.
//

import SwiftUI

struct ContentView: View {
    @State private var eyesLookUp = false
    @State private var showHappyCat = false
    @State private var showSadCat = false
    @State private var happyResetTask: Task<Void, Never>?
    @State private var sadResetTask: Task<Void, Never>?
    @State private var floatingFruitNames: [String] = []
    @State private var floatingFruitFrames: [String: CGRect] = [:]
    @State private var panelItemFrames: [String: CGRect] = [:]
    @State private var dragOffsets: [String: CGSize] = [:]
    @State private var matchedFruits: Set<String> = []

    private let topFruits = ["bananaImage", "appleImage", "raspberryImage", "strawberryImage", "kiwiImage"]
    private let selectedFruits = ["strawberryButtonImage", "kiwiButtonImage"]
    private let basketFruits = ["raspberryButtonImage", "appleButtonImage", "bananaButtonImage"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("bgImage")
                        .resizable()

                    ZStack {
                        Image("kittenBaseImage")
                            .resizable()
                            .scaledToFit()
                            .opacity((showHappyCat || showSadCat) ? 0 : 1)

                        Image("kittenHappyImage")
                            .resizable()
                            .scaledToFit()
                            .opacity(showHappyCat ? 1 : 0)

                        Image("kittenSadImage")
                            .resizable()
                            .scaledToFit()
                            .opacity(showSadCat ? 1 : 0)
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
                                .opacity((showHappyCat || showSadCat) ? 0 : 1)
                        }
                        .overlay {
                            Image("eyeLidsImage")
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(0.4)
                                .offset(y: -geometry.size.width * 0.2)
                                .opacity((showHappyCat || showSadCat) ? 0 : 1)
                        }
                        .animation(.easeInOut(duration: 0.3), value: showHappyCat)
                        .animation(.easeInOut(duration: 0.3), value: showSadCat)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                                eyesLookUp = true
                            }
                        }
                }
                .ignoresSafeArea(edges: .all)

                VStack(spacing: 0) {
                    topControls(size: geometry.size.width * 0.15)
                        .padding(.horizontal, 16)
                        .padding(.top, -16)

                    floatingFruits(size: geometry.size.width * 0.3, fruits: floatingFruitNames)

                    Spacer(minLength: 0)

                    selectionPanel(size: geometry.size.width * 0.26)
                        .padding(.bottom, 16)
                }
                .ignoresSafeArea(edges: .bottom)
            }
            .coordinateSpace(name: "gameArea")
            .onAppear {
                if floatingFruitNames.isEmpty {
                    floatingFruitNames = Array(topFruits.shuffled().prefix(3))
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
                ForEach(selectedFruits, id: \.self) { fruit in
                    draggablePanelFruit(imageName: fruit, size: size)
                }
            }

            HStack(spacing: 18) {
                ForEach(basketFruits, id: \.self) { fruit in
                    draggablePanelFruit(imageName: fruit, size: size)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .onPreferenceChange(PanelFruitFrameKey.self) { value in
            panelItemFrames.merge(value) { _, new in new }
        }
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
                dragOffsets[imageName] = .zero
            }
            triggerHappyCatAnimation()
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                dragOffsets[imageName] = .zero
            }
            if isDroppedOnAnyFloatingFruit {
                triggerSadCatAnimation()
            }
        }
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

#Preview {
    ContentView()
}
