//
//  AuthOTPIntent.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

/// The purpose of the OTP request. Values match the Supabase edge function contract.
enum AuthOTPIntent: String, Encodable, Sendable {
        case signup
        case login
}
