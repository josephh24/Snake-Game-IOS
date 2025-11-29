//
//  ContentView.swift
//  test
//
//  Created by jose pablo sanchez guillen on 21/11/25.
//

import SwiftUI

private enum LayoutConstants {
    static let boardFixedHeight: CGFloat = 420
    static let boardHeightFactor: CGFloat = 0.6
    static let tileInset: CGFloat = 2
    static let cornerRadius: CGFloat = 8
    static let controlButtonWidth: CGFloat = 64
    static let controlButtonHeight: CGFloat = 44
    static let smallButtonVertical: CGFloat = 8
    static let smallButtonHorizontal: CGFloat = 14
}

struct ContentView: View {
    @StateObject private var vm = SnakeViewModel()

    @State private var showMenu: Bool = true
    @State private var dragStart: CGPoint?

    var body: some View {
        ZStack {
            vm.theme.backgroundColor.ignoresSafeArea()

            VStack(spacing: 12) {
                headerView

                boardView
                    .gesture(dragGesture)
                    .padding(.top, 6)

                controlView
                    .padding(.top, 10)

                Spacer()
            }
            .padding()

            if showMenu {
                menuOverlay
            }

            if vm.isGameOver && !showMenu {
                gameOverOverlay
            }
        }
        .onAppear { vm.start() }
    }

    // HEADER
    private var headerView: some View {
        VStack(spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Text("🐍").font(.title)
                    Text("SNAKE").font(.system(size: 26, weight: .bold, design: .monospaced))
                        .foregroundColor(vm.theme.snakeColor)
                }
                Spacer()
                HStack(spacing: 12) {
                    Button(action: { withAnimation { showMenu.toggle() } }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.headline)
                            .foregroundStyle(vm.theme.hudTextColor)
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    }
                    .accessibilityLabel("Abrir menú de opciones")

                    VStack(alignment: .trailing) {
                        Text("Puntos: \(vm.score)").font(.headline)
                            .foregroundStyle(vm.theme.hudTextColor)
                        Text("Mejor: \(vm.highScore)").font(.subheadline).opacity(0.8)
                            .foregroundStyle(vm.theme.hudTextColor)
                    }
                }
            }

            ProgressView(value: min(1.0, Double(vm.score) / 20.0))
                .tint(vm.theme.snakeColor)
                .accessibilityLabel("Progreso de puntos")
                .accessibilityValue(Text("\(vm.score) de 20"))
        }
    }

    // BOARD
    private var boardView: some View {
        GeometryReader { geo in
            let cell = vm.theme.cellSize
            let size = min(geo.size.width, geo.size.height * LayoutConstants.boardHeightFactor)
            let boardSize = cell * CGFloat(vm.gridSize)
            let scale = min(size / boardSize, 1.0)
            let cellScaled = cell * scale
            let snakeTileSize = cellScaled - LayoutConstants.tileInset
            let displaySize = boardSize * scale

            ZStack(alignment: .topLeading) {
                Rectangle()
                    .fill(vm.theme.backgroundColor)
                    .frame(width: displaySize, height: displaySize)
                    .overlay(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).stroke(Color.white.opacity(0.03), lineWidth: 0))

                GridBackground(columns: vm.gridSize, rows: vm.gridSize, cellSize: cellScaled, color: vm.theme.gridLineColor)

                ForEach(0..<vm.snake.count, id: \.self) { i in
                    Rectangle()
                        .fill(vm.theme.snakeColor)
                        .frame(width: snakeTileSize, height: snakeTileSize)
                        .offset(x: vm.snake[i].x * cellScaled, y: vm.snake[i].y * cellScaled)
                        .animation(.linear(duration: 0.08), value: vm.snake)
                }

                Circle()
                    .fill(vm.theme.foodColor)
                    .frame(width: cellScaled * (vm.foodPulse ? 1.25 : 1.0),
                           height: cellScaled * (vm.foodPulse ? 1.25 : 1.0))
                    .offset(x: vm.food.x * cellScaled + (cellScaled - cellScaled * (vm.foodPulse ? 1.25 : 1.0)) / 2,
                            y: vm.food.y * cellScaled + (cellScaled - cellScaled * (vm.foodPulse ? 1.25 : 1.0)) / 2)
                    .animation(.easeOut(duration: 0.18), value: vm.foodPulse)
            }
            .frame(width: displaySize, height: displaySize)
            .clipped()
            .centerInParent(geoSize: geo.size)
        }
        .frame(height: LayoutConstants.boardFixedHeight)
    }

    // CONTROLS
    private var controlView: some View {
        VStack(spacing: 14) {
            HStack(spacing: 40) {
                Button(action: { vm.changeDirection(.left) }) { controlButton("◀️") }
                    .accessibilityLabel("Izquierda")
                VStack(spacing: 8) {
                    Button(action: { vm.changeDirection(.up) }) { controlButton("🔼") }
                        .accessibilityLabel("Arriba")
                    Button(action: { vm.changeDirection(.down) }) { controlButton("🔽") }
                        .accessibilityLabel("Abajo")
                }
                Button(action: { vm.changeDirection(.right) }) { controlButton("▶️") }
                    .accessibilityLabel("Derecha")
            }

            HStack(spacing: 20) {
                Button(action: { vm.togglePause() }) {
                    smallButton(vm.isPaused ? "Reanudar" : "Pausa")
                }
                .accessibilityLabel(vm.isPaused ? "Reanudar" : "Pausa")
                Button(action: { vm.restart() }) {
                    smallButton("Reiniciar")
                }
                .accessibilityLabel("Reiniciar")
                Button(action: { vm.toggleTurbo() }) {
                    smallButton(vm.turboActive ? "Normal" : "Turbo")
                }
                .accessibilityLabel(vm.turboActive ? "Modo normal" : "Turbo")
            }
        }
    }

    // MENU
    private var menuOverlay: some View {
        VStack(spacing: 12) {
            Text("SNAKE").font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(vm.theme.snakeColor)
                .shadow(color: .black.opacity(0.6), radius: 4, x: 0, y: 1)
            Text("Controles: swipe o usa los botones. Mantén Turbo para acelerar.")
                .multilineTextAlignment(.center)
                .foregroundColor(.white)

            Picker("Tema", selection: $vm.theme) {
                ForEach(GameTheme.allCases, id: \.self) { t in
                    Text(t.rawValue).foregroundColor(.white)
                }
            }
            .pickerStyle(.segmented)
            .tint(vm.theme.snakeColor)
            .padding(.horizontal, 20)

            Button(action: {
                vm.restart()
                showMenu = false
            }) {
                smallButton("Comenzar")
            }

            Button(action: { showMenu = false }) {
                Text("Cerrar").foregroundColor(.white)
            }
        }
        .padding(22)
        .frame(maxWidth: 420)
        .background(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).fill(Color.black.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).stroke(vm.theme.snakeColor, lineWidth: 2))
        .shadow(radius: 16)
        .preferredColorScheme(.dark)
    }

    // GAME OVER
    private var gameOverOverlay: some View {
        VStack(spacing: 14) {
            Text("GAME OVER").font(.system(size: 32, weight: .bold, design: .monospaced)).foregroundColor(.red)
            Text("Puntos: \(vm.score)")
            Text("Mejor: \(vm.highScore)")
            HStack(spacing: 12) {
                Button(action: { vm.restart(); }) { smallButton("Jugar otra vez") }
                Button(action: { showMenu = true }) { smallButton("Menu") }
            }
        }
        .padding(22)
        .frame(maxWidth: 420)
        .background(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).fill(Color.black.opacity(0.9)))
        .overlay(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).stroke(Color.red, lineWidth: 2))
        .shadow(radius: 24)
    }

    // Drag gesture (swipe)
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 10).onEnded { value in
            let dx = value.translation.width
            let dy = value.translation.height
            if abs(dx) > abs(dy) {
                vm.changeDirection(dx > 0 ? .right : .left)
            } else {
                vm.changeDirection(dy > 0 ? .down : .up)
            }
        }
    }

    // Helpers
    private func controlButton(_ emoji: String) -> some View {
        Text(emoji)
            .font(.largeTitle)
            .frame(width: LayoutConstants.controlButtonWidth, height: LayoutConstants.controlButtonHeight)
            .background(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).fill(Color.white.opacity(0.06)))
            .accessibilityAddTraits(.isButton)
    }

    private func smallButton(_ label: String) -> some View {
        Text(label)
            .font(.callout)
            .padding(.vertical, LayoutConstants.smallButtonVertical)
            .padding(.horizontal, LayoutConstants.smallButtonHorizontal)
            .background(RoundedRectangle(cornerRadius: LayoutConstants.cornerRadius).fill(Color.white.opacity(0.06)))
            .accessibilityAddTraits(.isButton)
    }
}

// Small helper to center in GeometryReader
fileprivate extension View {
    func centerInParent(geoSize: CGSize) -> some View {
        self.frame(width: geoSize.width, height: geoSize.height, alignment: .center)
    }
}

// GridBackground used in boardView
struct GridBackground: View {
    let columns: Int
    let rows: Int
    let cellSize: CGFloat
    let color: Color

    var body: some View {
        Path { path in
            for c in 0...columns {
                let x = CGFloat(c) * cellSize
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: CGFloat(rows) * cellSize))
            }
            for r in 0...rows {
                let y = CGFloat(r) * cellSize
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: CGFloat(columns) * cellSize, y: y))
            }
        }
        .stroke(color, lineWidth: 1)
        .frame(width: CGFloat(columns) * cellSize, height: CGFloat(rows) * cellSize)
    }
}
