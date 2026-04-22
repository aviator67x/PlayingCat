//
//  ContentView.swift
//  PlayingCat
//
//  Created by Andrew Kasilov on 21.04.26.
//

import SwiftUI

struct ContentView: View {
    private let topFruits = ["bananaImage", "appleImage", "raspberryImage", "strawberryImage", "kiwiImage"]
    private var randomTopFruits: [String] { Array(topFruits.shuffled().prefix(3)) }
    private let selectedFruits = ["strawberryButtonImage", "kiwiButtonImage"]
    private let basketFruits = ["raspberryButtonImage", "appleButtonImage", "bananaButtonImage"]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ZStack {
                    Image("bgImage")
                        .resizable()

                    Image("kittenBaseImage")
                        .resizable()
                        .scaledToFit()
                }
                .ignoresSafeArea(edges: .all)

                VStack(spacing: 0) {
                    topControls(size: geometry.size.width * 0.15)
                        .padding(.horizontal, 16)
                        .padding(.top, -16)

                    floatingFruits(size: geometry.size.width * 0.3, fruits: randomTopFruits)

                    Spacer(minLength: 0)

                    selectionPanel(size: geometry.size.width * 0.26)
                        .padding(.bottom, 16)
                }
                .ignoresSafeArea(edges: .bottom)
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
            Image(fruits[0])
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.2)

            Spacer()

            Image(fruits[2])
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.2)
        }
        .padding(.horizontal, 12)
        .overlay {
            Image(fruits[1])
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size * 1.2)
                .offset(x: 10)
                .padding(.top, -size / 1.0)
        }
    }

    private func selectionPanel(size: CGFloat) -> some View {
        VStack {
            HStack(spacing: 18) {
                ForEach(selectedFruits, id: \.self) { fruit in
                    gameCircleButton(imageName: fruit, size: size)
                }
            }

            HStack(spacing: 18) {
                ForEach(basketFruits, id: \.self) { fruit in
                    gameCircleButton(imageName: fruit, size: size)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func gameCircleButton(imageName: String, size: CGFloat) -> some View {
        Button {
            // UI scaffold only.
        } label: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ContentView()
}
