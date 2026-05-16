//
//  OTPVerifyView.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import SwiftUI

struct OTPVerifyView: View {

    @Bindable var viewModel: OTPVerifyViewModel

    var body: some View {
        NavigationStack {
            Form {
                codeSection
                verifyButton
                stateOverlay
            }
            .navigationTitle("Enter Code")
            .disabled(viewModel.state == .loading)
        }
    }
}

// MARK: - Subviews

private extension OTPVerifyView {

    var codeSection: some View {
        Section {
            TextField("6-digit code", text: $viewModel.otpCode)
                .keyboardType(.numberPad)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
        } header: {
            Text("A code was sent to \(viewModel.email)")
        }
    }

    var verifyButton: some View {
        Section {
            Button {
                Task { await viewModel.verify() }
            } label: {
                HStack {
                    Spacer()
                    if viewModel.state == .loading {
                        ProgressView()
                    } else {
                        Text("Verify")
                    }
                    Spacer()
                }
            }
            .disabled(viewModel.otpCode.isEmpty)
        }
    }

    @ViewBuilder
    var stateOverlay: some View {
        switch viewModel.state {
        case .success:
            Section {
                Label("Verified! Signing you in…", systemImage: "checkmark.circle.fill")
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
