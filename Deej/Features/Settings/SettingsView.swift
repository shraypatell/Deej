//
//  SettingsView.swift
//  Edit-profile + reset-account screen. Reachable from the ProfileView's
//  gear icon.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppServices.self) private var services
    @Environment(\.dismiss) private var dismiss

    @State private var username: String = ""
    @State private var displayName: String = ""
    @State private var bio: String = ""
    @State private var location: String = ""
    @State private var isSaving: Bool = false
    @State private var saveError: String?
    @State private var showResetConfirm: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            header
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    profileSection
                    accountSection
                    aboutSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
        }
        .background(Color.deejBgCanvas.ignoresSafeArea())
        .task { seedFromUser() }
        .alert("Reset account?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                Task { await services.signOut(); dismiss() }
            }
        } message: {
            Text("Signs you out of this device. Your data stays in the cloud.")
        }
    }

    // MARK: header
    private var header: some View {
        HStack {
            Button { dismiss() } label: {
                Text("CANCEL")
                    .font(.deejMono(10, weight: .bold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(2)
            }
            .buttonStyle(.plain)
            Spacer()
            VStack(spacing: 2) {
                Text("MODULE")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejTextFaint)
                    .deejTracking(1.5)
                Text("SETTINGS")
                    .font(.deejMono(13, weight: .bold))
                    .foregroundStyle(.deejCream)
                    .deejTracking(1)
            }
            Spacer()
            Button {
                Task { await save() }
            } label: {
                Text(isSaving ? "…" : "SAVE")
                    .font(.deejMono(10, weight: .bold))
                    .foregroundStyle(.deejOrangeHigh)
                    .deejTracking(2)
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 16)
        .overlay(alignment: .bottom) {
            Rectangle().fill(Color.deejBgPanelEdge).frame(height: 1)
        }
    }

    // MARK: profile
    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("PROFILE", subtitle: "PUBLIC")
            field(label: "USERNAME",     placeholder: "@username", text: $username, autocapitalize: false)
            field(label: "DISPLAY_NAME", placeholder: "your real name", text: $displayName, autocapitalize: true)
            field(label: "BIO",          placeholder: "one line about your taste",
                  text: $bio, autocapitalize: true)
            field(label: "LOCATION",     placeholder: "BKLYN, NY", text: $location, autocapitalize: true)

            if let err = saveError {
                Text(err)
                    .font(.deejMono(9, weight: .semibold))
                    .foregroundStyle(.deejStatusRed)
            }
        }
    }

    // MARK: account
    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("ACCOUNT", subtitle: "ANONYMOUS")
            VStack(alignment: .leading, spacing: 4) {
                Text("USER_ID")
                    .font(.deejMono(8, weight: .semibold))
                    .foregroundStyle(.deejCreamDim)
                    .deejTracking(1.5)
                Text(services.currentUser?.id.uuidString ?? "—")
                    .font(.deejMono(9, weight: .medium))
                    .foregroundStyle(.deejOrangeLow)
                    .textSelection(.enabled)
            }
            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Text("RESET_ACCOUNT")
                    .font(.deejMono(11, weight: .bold))
                    .deejTracking(2)
            }
            .buttonStyle(.hardware(.destructive))
            .frame(height: 48)
            .padding(.top, 6)
        }
    }

    // MARK: about
    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("ABOUT", subtitle: "v0.1")
            VStack(alignment: .leading, spacing: 4) {
                aboutRow("BUILD",     value: "0.1.0 · debug")
                aboutRow("BACKEND",   value: "supabase · anonymous")
                aboutRow("TOTAL_LOGS",  value: "\(services.orderedLogs.count)")
                aboutRow("FRIENDS",     value: "\(services.acceptedFriendships.count)")
            }
        }
    }

    private func aboutRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            Spacer()
            Text(value)
                .font(.deejMono(10, weight: .semibold))
                .foregroundStyle(.deejOrangeMid)
                .deejTracking(0.5)
        }
        .padding(.vertical, 4)
    }

    // MARK: helpers
    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        HStack {
            Text(title)
                .font(.deejMono(10, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            Spacer()
            Text(subtitle)
                .font(.deejMono(9, weight: .semibold))
                .foregroundStyle(.deejOrangeLow)
                .deejTracking(1.2)
        }
    }

    private func field(label: String, placeholder: String,
                       text: Binding<String>, autocapitalize: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.deejMono(8, weight: .semibold))
                .foregroundStyle(.deejCreamDim)
                .deejTracking(1.5)
            TextField("", text: text, prompt:
                Text(placeholder)
                    .font(.deejMono(13, weight: .semibold))
                    .foregroundStyle(.deejOrangeLow))
                .font(.deejMono(13, weight: .semibold))
                .foregroundStyle(.deejCream)
                .textInputAutocapitalization(autocapitalize ? .sentences : .never)
                .autocorrectionDisabled()
                .padding(.horizontal, 14)
                .frame(height: 44)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.deejButtonDark)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(Color.deejBgPanelEdge, lineWidth: 1)
                        }
                }
        }
    }

    private func seedFromUser() {
        guard let u = services.currentUser else { return }
        username     = u.username.replacingOccurrences(of: "@", with: "")
        displayName  = u.displayName ?? ""
        bio          = u.bio ?? ""
        location     = u.location ?? ""
    }

    private func save() async {
        guard !isSaving else { return }
        isSaving = true
        saveError = nil
        let cleanUsername = username
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "@", with: "")
        let ok = await services.updateProfile(
            username: cleanUsername.isEmpty ? nil : cleanUsername,
            displayName: displayName.trimmingCharacters(in: .whitespaces).isEmpty
                ? nil : displayName,
            bio: bio.trimmingCharacters(in: .whitespaces).isEmpty ? nil : bio,
            location: location.trimmingCharacters(in: .whitespaces).isEmpty ? nil : location
        )
        isSaving = false
        if ok {
            dismiss()
        } else {
            saveError = services.lastError ?? "couldn't save · try a different username"
        }
    }
}

#Preview {
    SettingsView()
        .environment(AppServices())
        .preferredColorScheme(.dark)
}
