import SwiftUI
import UserNotifications

struct MainScreen: View {
    // MARK: - State Variables
    @State private var timeSpent: Int = 0 // Tracks seconds spent in the app
    @State private var isLocked: Bool = false // Controls lockout state
    @State private var timeLimit: Int = 600 // Default limit: 10 minutes (600 seconds)
    @State private var showUnlockConfirmation: Bool = false // Shows the unlock confirmation dialog
    @State private var unlockCountdown: Int = 0 // Countdown for unlock delay
    @State private var starTwinkle: Bool = false // For star animation
    
    // MARK: - Timers
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // Timer for tracking screen time
    let unlockTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect() // Timer for unlock delay
    let twinkleTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect() // Timer for star animation
    
    // MARK: - Managers and Storage
    let notificationManager = NotificationManager() // Handles notifications
    private let userDefaults = UserDefaults.standard // For persisting lockout state
    private let lockoutStartKey = "lockoutStartTime" // Key for lockout start time
    private let timeSpentKey = "timeSpent" // Key for time spent
    
    // MARK: - Computed Properties
    // Check if 5 minutes remain before the limit
    private var isFiveMinutesBeforeLimit: Bool {
        timeLimit >= 300 && timeSpent == (timeLimit - 300) // 300 seconds = 5 minutes
    }
    
    // Calculate seconds until midnight
    private var secondsUntilMidnight: Int {
        let calendar = Calendar.current
        let now = Date()
        let midnight = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        return Int(midnight.timeIntervalSince(now))
    }
    
    // Format remaining time as "HH:MM:SS"
    private var remainingTimeFormatted: String {
        let hours = secondsUntilMidnight / 3600
        let minutes = (secondsUntilMidnight % 3600) / 60
        let seconds = secondsUntilMidnight % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - Initialization
    // Initialize lockout state when the view loads
    init() {
        if let lockoutStart = userDefaults.object(forKey: lockoutStartKey) as? Date {
            let calendar = Calendar.current
            let lockoutDay = calendar.startOfDay(for: lockoutStart)
            let today = calendar.startOfDay(for: Date())
            
            if lockoutDay == today {
                _isLocked = State(initialValue: true)
                _timeSpent = State(initialValue: userDefaults.integer(forKey: timeSpentKey))
            } else {
                clearLockoutState()
            }
        }
    }
    
    // MARK: - Helper Functions
    // Save lockout state to UserDefaults
    private func saveLockoutState() {
        userDefaults.set(Date(), forKey: lockoutStartKey)
        userDefaults.set(timeSpent, forKey: timeSpentKey)
    }
    
    // Clear lockout state from UserDefaults
    private func clearLockoutState() {
        userDefaults.removeObject(forKey: lockoutStartKey)
        userDefaults.removeObject(forKey: timeSpentKey)
    }
    
    // Unlock the app after the delay
    private func forceUnlock() {
        isLocked = false
        timeSpent = 0
        clearLockoutState()
        showUnlockConfirmation = false
        unlockCountdown = 0
    }
    
    // MARK: - UI
    var body: some View {
        NavigationView {
            ZStack {
                // Main UI content
                VStack(spacing: 20) {
                    // App title with a spacey font style
                    Text("Pause")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .purple.opacity(0.5), radius: 5, x: 0, y: 0) // Glow effect
                    
                    // Display current screen time
                    Text("Screen Time: \(timeSpent) seconds")
                        .font(.title2)
                        .foregroundColor(.white.opacity(starTwinkle ? 1.0 : 0.8)) // Twinkle effect
                    
                    // Time limit input with a spacey border
                    TextField("Time Limit (seconds)", value: $timeLimit, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)
                        .keyboardType(.numberPad)
                        .disabled(isLocked)
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.purple, lineWidth: 2)
                        )
                }
                
                // Lockout screen
                if isLocked {
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                        .overlay(
                            VStack(spacing: 20) {
                                Text("Orbiting Break Mode!")
                                    .font(.title)
                                    .foregroundColor(.white)
                                    .shadow(color: .blue.opacity(0.5), radius: 5, x: 0, y: 0)
                                Text("Returns in: \(remainingTimeFormatted)")
                                    .font(.title2)
                                    .foregroundColor(.white.opacity(starTwinkle ? 1.0 : 0.8))
                                // Show countdown during unlock process
                                if unlockCountdown > 0 {
                                    Text("Re-entering Orbit in: \(unlockCountdown) seconds")
                                        .font(.headline)
                                        .foregroundColor(.yellow)
                                }
                                // Button to start the unlock process
                                Button(action: {
                                    showUnlockConfirmation = true
                                }) {
                                    Text("Re-Enter Orbit Early")
                                        .font(.headline)
                                        .padding()
                                        .background(unlockCountdown > 0 ? Color.gray : Color.red)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                                .disabled(unlockCountdown > 0)
                                NavigationLink(destination: Settings()) {
                                    Text("Go to Space Station (Settings)")
                                        .font(.headline)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                }
                            }
                        )
                }
            }
            // Space-themed background with stars
            .background(
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .blue.opacity(0.8)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    // Add star-like dots
                    ForEach(0..<20) { _ in
                        Circle()
                            .frame(width: 2, height: 2)
                            .foregroundColor(.white.opacity(starTwinkle ? 0.8 : 0.3))
                            .position(
                                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                            )
                    }
                }
                .ignoresSafeArea()
            )
            .navigationTitle("Pause")
            // MARK: - Timer Logic
            .onReceive(timer) { _ in
                if !isLocked {
                    timeSpent += 1
                    if isFiveMinutesBeforeLimit {
                        notificationManager.scheduleReminder(after: 5)
                    }
                    if timeSpent >= timeLimit {
                        isLocked = true
                        saveLockoutState()
                        notificationManager.scheduleLockoutNotification()
                    }
                }
            }
            .onReceive(unlockTimer) { _ in
                if unlockCountdown > 0 {
                    unlockCountdown -= 1
                    if unlockCountdown == 0 {
                        forceUnlock()
                    }
                }
            }
            // Star twinkle animation
            .onReceive(twinkleTimer) { _ in
                withAnimation(.easeInOut(duration: 1)) {
                    starTwinkle.toggle()
                }
            }
            // Request notification permission
            .onAppear {
                notificationManager.requestPermission()
            }
            // Show confirmation dialog for unlocking
            .alert(isPresented: $showUnlockConfirmation) {
                Alert(
                    title: Text("Re-Enter Orbit Early?"),
                    message: Text("Are you sure you want to leave break mode? This will reset your timer. You’ll need to wait 10 seconds for re-entry."),
                    primaryButton: .destructive(Text("Yes")) {
                        unlockCountdown = 10
                    },
                    secondaryButton: .cancel()
                )
            }
        }
    }
}

struct MainScreen_Previews: PreviewProvider {
    static var previews: some View {
        MainScreen()
    }
}
