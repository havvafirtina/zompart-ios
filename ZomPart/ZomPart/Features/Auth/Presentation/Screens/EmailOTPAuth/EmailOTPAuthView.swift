//
//  EmailOTPAuthView.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import SwiftUI

struct EmailOTPAuthView: View {

    @State private var viewModel: EmailOTPAuthViewModel

    @State private var email = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var intent: AuthOTPIntent = .signup

    init(viewModel: EmailOTPAuthViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Form {
                intentSection
                fieldsSection
                sendButton
                stateOverlay
            }
            .navigationTitle("Sign In")
            .disabled(viewModel.state == .loading)
        }
        .onAppear {
            print(DefaultEnvironment.debugDescription())
        }
    }
}

// MARK: - Subviews

private extension EmailOTPAuthView {

    var intentSection: some View {
        Picker("Intent", selection: $intent) {
            Text("Sign Up").tag(AuthOTPIntent.signup)
            Text("Log In").tag(AuthOTPIntent.login)
        }
        .pickerStyle(.segmented)
    }

    var fieldsSection: some View {
        Section {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            if intent == .signup {
                TextField("First Name", text: $firstName)
                    .textContentType(.givenName)

                TextField("Last Name", text: $lastName)
                    .textContentType(.familyName)
            }
        }
    }

    var sendButton: some View {
        Section {
            Button {
                Task {
                    await viewModel.sendOTP(
                        email: email,
                        intent: intent,
                        firstName: intent == .signup ? firstName : nil,
                        lastName: intent == .signup ? lastName : nil
                    )
                }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.state == .loading {
                        ProgressView()
                    } else {
                        Text("Send OTP")
                    }
                    Spacer()
                }
            }
            .disabled(email.isEmpty)
        }
    }

    @ViewBuilder
    var stateOverlay: some View {
        switch viewModel.state {
        case .success:
            Section {
                Label("OTP sent! Check your email.", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
            }
        case .error(let message):
            Section {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
            }
        default:
            EmptyView()
        }
    }
}
