//
//  SnakeViewModel.swift
//  test
//
//  Created by jose pablo sanchez guillen on 21/11/25.
//

import SwiftUI
import AVFoundation
import Combine

enum Direction {
    case up, down, left, right
}

@MainActor
class SnakeViewModel: ObservableObject {

    private enum StorageKeys {
        static let highScore = "snake_highscore_v1"
    }

    // Published state
    @Published var snake: [CGPoint] = [CGPoint(x: 7, y: 7)]
    @Published var food: CGPoint = CGPoint(x: 3, y: 4)
    @Published var direction: Direction = .right
    @Published var score: Int = 0
    @Published var highScore: Int = UserDefaults.standard.integer(forKey: StorageKeys.highScore)
    @Published var isGameOver: Bool = false
    @Published var isPaused: Bool = false
    @Published var theme: GameTheme = .classic
    @Published var foodPulse: Bool = false
    @Published var turboActive: Bool = false

    // HUD color that adapts to the selected theme so the score is always visible
    var hudTextColor: Color {
        switch theme {
        case .classic:
            return .primary
        default:
            return .white
        }
    }

    // Grid and speed
    let gridSize: Int = 20

    private var gameTask: Task<Void, Never>?

    /// Velocidades FIJAS (la clave del turbo estable)
    let normalSpeed: TimeInterval = 0.15
    let turboSpeed: TimeInterval  = 0.07

    private var currentSpeed: TimeInterval

    private let minSpeed: TimeInterval = 0.03
    private var speedLevel: Int = 0

    // Audio
    private var eatSound: AVAudioPlayer?
    private var gameOverSound: AVAudioPlayer?

    init() {
        currentSpeed = normalSpeed
        loadSounds()
        restart()
    }

    private func loadSounds() {
        _ = AudioManager.shared
    }

    // =====================================================
    // MARK: - Game Control
    // =====================================================

    func start() {
        startLoop(speed: currentSpeed)
    }

    func restart() {
        stopLoop()

        let c = gridSize / 2
        snake = [
            CGPoint(x: c, y: c),
            CGPoint(x: c - 1, y: c),
            CGPoint(x: c - 2, y: c)
        ]

        direction = .right
        score = 0
        isGameOver = false
        isPaused = false

        currentSpeed = normalSpeed
        turboActive = false
        speedLevel = 0

        generateFood()
        startLoop(speed: currentSpeed)
    }

    func togglePause() {
        isPaused.toggle()
        if isPaused {
            stopLoop()
        } else {
            startLoop(speed: turboActive ? turboSpeed : currentSpeed)
        }
    }

    // =====================================================
    // MARK: - TURBO (nuevo sistema estable)
    // =====================================================

    func toggleTurbo() {
        turboActive.toggle()
        startLoop(speed: turboActive ? turboSpeed : currentSpeed)
    }

    // =====================================================
    // MARK: - Direction
    // =====================================================

    func changeDirection(_ d: Direction) {
        switch (direction, d) {
        case (.up, .down), (.down, .up), (.left, .right), (.right, .left):
            return
        default:
            direction = d
            AudioManager.shared.playClick()
            Haptics.shared.impact(.light)
        }
    }

    // =====================================================
    // MARK: - GAME LOOP
    // =====================================================

    private func startLoop(speed: TimeInterval) {
        stopLoop()
        gameTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(speed * 1_000_000_000))
                if !self.isPaused && !self.isGameOver {
                    self.tick()
                }
            }
        }
    }

    private func stopLoop() {
        gameTask?.cancel()
        gameTask = nil
    }

    private func tick() {
        if isGameOver || isPaused { return }
        moveSnake()
    }

    // =====================================================
    // MARK: - MOVEMENT LOGIC
    // =====================================================

    private func moveSnake() {
        guard var head = snake.first else { return }

        switch direction {
        case .up:    head.y -= 1
        case .down:  head.y += 1
        case .left:  head.x -= 1
        case .right: head.x += 1
        }

        // Wrap-around
        head.x = (head.x + CGFloat(gridSize)).truncatingRemainder(dividingBy: CGFloat(gridSize))
        head.y = (head.y + CGFloat(gridSize)).truncatingRemainder(dividingBy: CGFloat(gridSize))

        // Self collision
        if snake.contains(head) {
            gameOver()
            return
        }

        snake.insert(head, at: 0)

        if head == food {
            score += 1
            AudioManager.shared.playEat()
            Haptics.shared.impact(.medium)

            // Pulse effect
            foodPulse = true
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 180_000_000)
                withAnimation(.easeOut(duration: 0.18)) {
                    self.foodPulse = false
                }
            }

            generateFood()

            // Increase base speed every 5 points
            if score % 5 == 0 { increaseBaseSpeed() }

            if score > highScore {
                highScore = score
                UserDefaults.standard.set(highScore, forKey: StorageKeys.highScore)
            }

        } else {
            snake.removeLast()
        }
    }

    private func increaseBaseSpeed() {
        speedLevel += 1
        currentSpeed = max(minSpeed, currentSpeed * 0.88)

        // solo actualiza si NO está activo el turbo
        if !turboActive {
            startLoop(speed: currentSpeed)
        }
    }

    // =====================================================
    // MARK: - FOOD
    // =====================================================

    private func generateFood() {
        var p: CGPoint
        repeat {
            p = CGPoint(x: CGFloat(Int.random(in: 0..<gridSize)),
                        y: CGFloat(Int.random(in: 0..<gridSize)))
        } while snake.contains(p)
        food = p
    }

    // =====================================================
    // MARK: - GAME OVER
    // =====================================================

    private func gameOver() {
        isGameOver = true
        stopLoop()
        AudioManager.shared.playGameOver()
        Haptics.shared.notification(.error)
    }
}

