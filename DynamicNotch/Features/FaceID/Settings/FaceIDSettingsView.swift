//
//  FaceIDSettingsView.swift
//  DynamicNotch
//

import SwiftUI

struct FaceIDSettingsView: View {
    @ObservedObject var settings: FaceIDSettingsStore
    @ObservedObject var applicationSettings: ApplicationSettingsStore
    var notchViewModel: NotchViewModel?

    @StateObject private var service = FaceIDService.shared
    @State private var isShowingEnrollmentSheet = false
    @State private var isShowingResetConfirmation = false
    @State private var isShowingSecuritySheet = false
    @State private var hasStoredPassword = FaceIDKeychainService.hasPassword
    @State private var passwordInput = ""
    @State private var isVerifyingPassword = false
    @State private var passwordErrorMessage: String? = nil

    var body: some View {
        SettingsPageScrollView {
            faceIDGeneralCard
            faceEnrollmentCard
            faceIDAppearanceCard
            securityOptionsCard
        }
        .sheet(isPresented: $isShowingEnrollmentSheet) {
            FaceIDEnrollmentSheetView(settings: settings, service: service)
        }
        .sheet(isPresented: $isShowingSecuritySheet) {
            securityVerificationSheet
        }
        .confirmationDialog(
            "settings.faceid.reset.title",
            isPresented: $isShowingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("settings.faceid.reset.delete", role: .destructive) {
                settings.resetFace()
                FaceIDKeychainService.deletePassword()
                hasStoredPassword = false
            }
            Button("settings.faceid.security.cancel", role: .cancel) {}
        } message: {
            Text("settings.faceid.reset.message")
        }
        .onAppear {
            hasStoredPassword = FaceIDKeychainService.hasPassword
        }
    }

    private var faceIDGeneralCard: some View {
        SettingsCard(title: "settings.faceid.card.general") {
            SettingsToggleRow(
                title: "settings.faceid.toggle.enabled.title",
                description: "settings.faceid.toggle.enabled.desc",
                systemImage: "faceid",
                color: .green,
                isOn: $settings.isFaceIDEnabled,
                accessibilityIdentifier: "settings.faceid.enabled"
            )
            
            Divider()
                .opacity(0.6)
                .padding(.leading, 43)
            
            SettingsToggleRow(
                title: "settings.faceid.toggle.lockScreenButton.title",
                description: "settings.faceid.toggle.lockScreenButton.desc",
                systemImage: "ellipsis",
                color: .blue,
                isOn: $settings.showLockScreenButton,
                accessibilityIdentifier: "settings.faceid.showLockScreenButton"
            )
        }
    }

    private var faceEnrollmentDescription: LocalizedStringKey {
        if settings.isEnrolled && !settings.enrolledDateString.isEmpty {
            return LocalizedStringKey(applicationSettings.appLanguage.locale.dnFormat(
                "settings.faceid.status.enrolled.date",
                fallback: "Configured: %@ • Secured by Keychain",
                settings.enrolledDateString
            ))
        } else if settings.isEnrolled {
            return "settings.faceid.status.enrolled.active"
        } else {
            return "settings.faceid.status.notEnrolled.desc"
        }
    }

    private var faceEnrollmentCard: some View {
        SettingsCard(title: "settings.faceid.card.profile") {
            if settings.isEnrolled {
                SettingsMenuRow(
                    title: "settings.faceid.status.enrolled",
                    description: faceEnrollmentDescription,
                    options: FaceIDProfileAction.allCases,
                    optionTitle: { $0.title },
                    accessibilityIdentifier: "settings.faceid.profile",
                    selection: Binding(
                        get: { FaceIDProfileAction.configured },
                        set: { action in
                            switch action {
                            case .reconfigure:
                                requestSecurityVerification()
                            case .delete:
                                isShowingResetConfirmation = true
                            case .configured:
                                break
                            }
                        }
                    )
                )
            } else {
                SettingsButtonRow(
                    title: "settings.faceid.status.notEnrolled",
                    description: "settings.faceid.status.notEnrolled.desc",
                    systemImage: "person.crop.circle.badge.plus",
                    iconSize: 14,
                    iconColor: .white,
                    color: .blue,
                    buttonTitle: "settings.faceid.action.addFace",
                    accessibilityIdentifier: "settings.faceid.addFace"
                ) {
                    requestSecurityVerification()
                }
            }
        }
    }

    private var faceIDAppearanceCard: some View {
        SettingsCard(title: "settings.faceid.card.appearance") {
            CustomPicker(
                selection: $settings.presentationStyle,
                options: Array(FaceIDPresentationStyle.allCases),
                title: { $0.title },
                headerTitle: "settings.faceid.style.title",
                headerDescription: "settings.faceid.style.desc",
                itemHeight: 100,
                lightBackgroundImage: Image("backgroundLight"),
                darkBackgroundImage: Image("backgroundDark")
            ) { style, isSelected in
                faceIDStylePickerContent(for: style, isSelected: isSelected)
            }
        }
    }

    @ViewBuilder
    private func faceIDStylePickerContent(for style: FaceIDPresentationStyle, isSelected: Bool) -> some View {
        switch style {
        case .expanded:
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.black)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(faceIDPreviewStrokeColor, lineWidth: 1)
                    }

                Image(systemName: "faceid")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(.green)
            }
            .frame(width: 64, height: 64)
            .environment(\.colorScheme, .dark)
            .scaleEffect(isSelected ? 1 : 0.97)

        case .compact:
            ZStack {
                Capsule()
                    .fill(.black)
                    .overlay {
                        Capsule()
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }

                HStack {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)

                    Spacer()

                    Image(systemName: "faceid")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.green)
                }
                .padding(.horizontal, 12)
            }
            .frame(width: 170, height: 40)
            .environment(\.colorScheme, .dark)
            .scaleEffect(isSelected ? 1 : 0.97)
        }
    }

    private var faceIDPreviewStrokeColor: Color {
        applicationSettings.isShowNotchStrokeEnabled ? .green.opacity(0.3) : .clear
    }

    private var securityOptionsCard: some View {
        SettingsCard(title: "settings.faceid.card.security") {
            SettingsToggleRow(
                title: "settings.faceid.toggle.requireAttention.title",
                description: "settings.faceid.toggle.requireAttention.desc",
                systemImage: "eye.fill",
                color: .red,
                isOn: $settings.requireAttention,
                accessibilityIdentifier: "settings.faceid.requireAttention"
            )

            Divider()
                .opacity(0.6)
                .padding(.leading, 43)

            SettingsToggleRow(
                title: "settings.faceid.toggle.unlockOnWake.title",
                description: "settings.faceid.toggle.unlockOnWake.desc",
                systemImage: "lock.open.display",
                color: .black,
                stroke: true,
                isOn: $settings.unlockOnWake,
                accessibilityIdentifier: "settings.faceid.unlockOnWake"
            )
        }
    }

    private var securityVerificationSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "key.viewfinder")
                .font(.system(size: 40))
                .foregroundStyle(.green)
                .padding(.top, 4)

            Text("settings.faceid.security.title")
                .font(.system(size: 16, weight: .bold))

            Text("settings.faceid.security.desc")
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 10)

            VStack(alignment: .leading, spacing: 6) {
                SecureField("settings.faceid.security.passwordPlaceholder", text: $passwordInput)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 300)
                    .disabled(isVerifyingPassword)
                    .onChange(of: passwordInput) { _, _ in
                        if passwordErrorMessage != nil {
                            passwordErrorMessage = nil
                        }
                    }
                    .onSubmit {
                        confirmSecurityVerification()
                    }

                if let passwordErrorMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 11))
                        Text(passwordErrorMessage)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundStyle(.red)
                    .frame(maxWidth: 300, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 12) {
                Button("settings.faceid.security.cancel") {
                    passwordInput = ""
                    passwordErrorMessage = nil
                    isVerifyingPassword = false
                    isShowingSecuritySheet = false
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                .disabled(isVerifyingPassword)

                Button(action: {
                    confirmSecurityVerification()
                }) {
                    HStack(spacing: 6) {
                        if isVerifyingPassword {
                            ProgressView()
                                .controlSize(.small)
                            Text("settings.faceid.security.verifying")
                        } else {
                            Text("settings.faceid.security.continue")
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(passwordInput.isEmpty || isVerifyingPassword)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.top, 4)
        }
        .padding(24)
        .frame(width: 390)
    }

    private func requestSecurityVerification() {
        passwordInput = ""
        passwordErrorMessage = nil
        isVerifyingPassword = false
        isShowingSecuritySheet = true
    }

    private func confirmSecurityVerification() {
        let trimmed = passwordInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isVerifyingPassword else { return }

        isVerifyingPassword = true
        passwordErrorMessage = nil

        let enteredPassword = passwordInput
        DispatchQueue.global(qos: .userInitiated).async {
            let isValid = FaceIDKeychainService.verifyPassword(enteredPassword)
            DispatchQueue.main.async {
                isVerifyingPassword = false
                if isValid {
                    _ = FaceIDKeychainService.savePassword(enteredPassword)
                    hasStoredPassword = true
                    passwordInput = ""
                    passwordErrorMessage = nil
                    isShowingSecuritySheet = false

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        startNotchEnrollment()
                    }
                } else {
                    passwordErrorMessage = L10n.string("settings.faceid.security.invalidPassword", language: applicationSettings.appLanguage)
                }
            }
        }
    }

    private func startNotchEnrollment() {
        guard let notchViewModel else {
            isShowingEnrollmentSheet = true
            return
        }

        let cameraService = FaceIDEnrollmentCameraService()
        let content = FaceIDEnrollmentNotchContent(
            step: .intro,
            settings: settings,
            notchViewModel: notchViewModel,
            cameraService: cameraService
        )
        notchViewModel.send(.showTemporaryNotification(content, duration: 180.0))
    }

    private func testFaceIDInNotch() {
        guard let notchViewModel else { return }

        let content = FaceIDNotchContent(service: service, style: settings.presentationStyle)
        notchViewModel.send(.showTemporaryNotification(content, duration: 8.0))

        service.startScan(
            requireOpenEyes: settings.requireOpenEyes,
            livenessCheck: settings.livenessCheck
        ) { [weak service, weak notchViewModel] _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                notchViewModel?.hideTemporaryNotification()
                service?.cancelScan()
            }
        }
    }
}

private enum FaceIDProfileAction: Hashable, CaseIterable {
    case configured
    case reconfigure
    case delete

    var title: LocalizedStringKey {
        switch self {
        case .configured:
            return "settings.faceid.action.enrolledMenu"
        case .reconfigure:
            return "settings.faceid.action.reconfigure"
        case .delete:
            return "settings.faceid.action.delete"
        }
    }
}

