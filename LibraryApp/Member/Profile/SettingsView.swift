import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var auth: AuthService
    let user: AppUser
    
    // AppStorage for persistence
    @AppStorage("pushNotificationsEnabled") private var pushNotificationsEnabled = true
    @AppStorage("includePDFsEnabled") private var includePDFsEnabled = true
    @AppStorage("dynamicTypeEnabled") private var dynamicTypeEnabled = false
    @AppStorage("voiceOverSupport") private var voiceOverSupport = false
    @AppStorage("hapticsEnabled") private var hapticsEnabled = true
    @AppStorage("iCloudSyncEnabled") private var iCloudSyncEnabled = true
    @AppStorage("offlineCacheEnabled") private var offlineCacheEnabled = true
    @AppStorage("appTheme") private var appTheme = "System"
    @AppStorage("faceIdEnabled") private var faceIdEnabled = false
    @AppStorage("selectedAppIcon") private var selectedAppIcon = "Default"
    
    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("App Theme", selection: $appTheme) {
                        Text("System").tag("System")
                        Text("Light").tag("Light")
                        Text("Dark").tag("Dark")
                    }
                    
                    Picker("App Icon", selection: $selectedAppIcon) {
                        Label("Classic", systemImage: "app.fill").tag("Default")
                        Label("Dark Mode", systemImage: "app.fill").tag("Dark")
                        Label("Gold Edition", systemImage: "app.dashed").tag("Gold")
                    }
                }
                
                Section("Security") {
                    Toggle(isOn: $faceIdEnabled) {
                        Label("Face ID / Touch ID", systemImage: "faceid")
                    }
                    .onChange(of: faceIdEnabled) { _, newValue in
                        auth.setBiometricEnabled(newValue, for: user, modelContext: modelContext)
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy").padding()) {
                        Label("Privacy & Security", systemImage: "shield.lefthalf.filled")
                    }
                }
                
                Section("Notifications & Data") {
                    Toggle(isOn: $pushNotificationsEnabled) {
                        Label("Push Notifications", systemImage: "bell.fill")
                    }
                    
                    Toggle(isOn: $iCloudSyncEnabled) {
                        Label("iCloud Sync", systemImage: "icloud.fill")
                    }
                    
                    Toggle(isOn: $offlineCacheEnabled) {
                        Label("Offline Mode", systemImage: "arrow.down.circle.fill")
                    }
                    
                    Button {
                        // Logic to export data as CSV/JSON
                    } label: {
                        Label("Export My Data", systemImage: "square.and.arrow.up")
                    }
                }
                
                Section("Experience") {
                    Toggle(isOn: $hapticsEnabled) {
                        Label("Haptic Feedback", systemImage: "hand.tap.fill")
                    }
                    
                    NavigationLink(destination: Text("Siri Shortcuts Configuration").padding()) {
                        Label("Siri Shortcuts", systemImage: "waveform")
                    }
                }
                
                Section("Support & About") {
                    Link(destination: URL(string: "https://example.com")!) {
                        Label("Help Center", systemImage: "questionmark.circle")
                    }
                    
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text("2.4.1 (Premium)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        auth.signOut()
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Log Out")
                                .fontWeight(.bold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                }
            }
        }
    }
}
