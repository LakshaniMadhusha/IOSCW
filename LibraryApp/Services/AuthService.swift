import Foundation
import SwiftData
import Combine
import FirebaseAuth
import FirebaseFirestore

enum AuthState {
    case signedOut
    case signedIn(AppUser)
}

final class AuthService: ObservableObject {
    @Published var state: AuthState = .signedOut
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var isAppLocked: Bool = false
    var lastBackgroundAt: Date? = nil
    let autoLockTimeoutSeconds: TimeInterval = 60
    
    private let loggedInUserIdKey = "loggedInUserIdKey"

    // Combine example: emit state changes for non-SwiftUI consumers
    private let stateSubject = CurrentValueSubject<AuthState, Never>(.signedOut)
    var statePublisher: AnyPublisher<AuthState, Never> { stateSubject.eraseToAnyPublisher() }

    private let biometric = BiometricAuthService()

    @MainActor
    func bootstrap(modelContext: ModelContext) {
        do {
            try MockData.seedIfNeeded(modelContext: modelContext)
            
            // Check native Firebase Session!
            if let userFirebase = Auth.auth().currentUser, let userEmail = userFirebase.email {
                let uuid = UUID(uuidString: userFirebase.uid) ?? UUID()
                
                let predicate = #Predicate<AppUser> { $0.email == userEmail }
                let descriptor = FetchDescriptor<AppUser>(predicate: predicate)
                
                if let localUser = try modelContext.fetch(descriptor).first {
                    state = .signedIn(localUser)
                    stateSubject.send(state)
                    // FaceID Lock parameter natively
                    isAppLocked = true
                }
            } else if let savedUserIdString = UserDefaults.standard.string(forKey: loggedInUserIdKey),
                      let savedUserId = UUID(uuidString: savedUserIdString) {
                // ... fallback to legacy defaults if auth absent
                let predicate = #Predicate<AppUser> { $0.id == savedUserId }
                let descriptor = FetchDescriptor<AppUser>(predicate: predicate)
                if let user = try modelContext.fetch(descriptor).first {
                    state = .signedIn(user)
                    stateSubject.send(state)
                    isAppLocked = true
                }
            }
        } catch {
            errorMessage = "Failed to load logic."
        }
    }

    @MainActor
    func signIn(email: String, password: String, role: UserRole, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Real Global Network Request!
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            let uid = result.user.uid
            
            // Fetch strict Role Metadata from the Cloud Sandbox
            let doc = try await Firestore.firestore().collection("users").document(uid).getDocument()
            
            guard let data = doc.data(),
                  let rawRole = data["role"] as? String else {
                errorMessage = "Account format corrupted remotely."
                return
            }
            
            if rawRole != role.rawValue {
                errorMessage = "Incorrect Role selected! Ensure you use the right portal."
                return
            }
            
            // Verify natively in local Cache or create dynamically
            let finalUID = UUID(uuidString: uid) ?? UUID()
            let predicate = #Predicate<AppUser> { $0.email == email }
            let descriptor = FetchDescriptor<AppUser>(predicate: predicate)
            
            if let localUser = try modelContext.fetch(descriptor).first {
                state = .signedIn(localUser)
                UserDefaults.standard.set(localUser.id.uuidString, forKey: loggedInUserIdKey)
                stateSubject.send(state)
            } else {
                // If it exists in the cloud but not locally, build it!
                let name = data["name"] as? String ?? "User"
                let newUser = AppUser(id: finalUID, name: name, email: email, password: password, role: role)
                modelContext.insert(newUser)
                try modelContext.save()
                state = .signedIn(newUser)
                UserDefaults.standard.set(newUser.id.uuidString, forKey: loggedInUserIdKey)
                stateSubject.send(state)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func signUp(name: String, email: String, password: String, role: UserRole, modelContext: ModelContext) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            // Enterprise Network Google Creation!
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid
            let parsedUUID = UUID(uuidString: uid) ?? UUID()
            
            // Push precise Identity metrics asynchronously into the specific Firebase metadata bucket natively
            let payload: [String: Any] = [
                "name": name,
                "email": email,
                "role": role.rawValue,
                "createdAt": FieldValue.serverTimestamp()
            ]
            try await Firestore.firestore().collection("users").document(uid).setData(payload)
            
            // Generate standard Local SwiftData counterpart
            let user = AppUser(id: parsedUUID, name: name, email: email, password: password, role: role)
            modelContext.insert(user)
            try modelContext.save()
            
            state = .signedIn(user)
            UserDefaults.standard.set(user.id.uuidString, forKey: loggedInUserIdKey)
            stateSubject.send(state)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func signIn(user: AppUser) {
        state = .signedIn(user)
        UserDefaults.standard.set(user.id.uuidString, forKey: loggedInUserIdKey)
        stateSubject.send(state)
    }

    @MainActor
    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("Error signing out from Firebase: \(error)")
        }
        state = .signedOut
        UserDefaults.standard.removeObject(forKey: loggedInUserIdKey)
        stateSubject.send(state)
        isAppLocked = false
    }

    func didEnterBackground() {
        lastBackgroundAt = .now
    }

    func willEnterForeground() {
        guard case .signedIn(let user) = state else { return }
        guard user.isBiometricEnabled else { return }
        guard let lastBackgroundAt else { return }
        guard Date().timeIntervalSince(lastBackgroundAt) >= autoLockTimeoutSeconds else { return }
        isAppLocked = true
    }

    @MainActor
    func unlockApp() async {
        errorMessage = nil
        do {
            try await biometric.authenticate(reason: "Unlock Library Companion")
            isAppLocked = false
            lastBackgroundAt = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    @MainActor
    func setBiometricEnabled(_ enabled: Bool, for user: AppUser, modelContext: ModelContext) {
        user.isBiometricEnabled = enabled
        try? modelContext.save()
    }
}

