//
//  ScanUploadUrlItemDomain.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation

struct ScanUploadUrlItemDomain: Equatable, Sendable {
        let photoId: String
        let uploadUrl: String
        let storagePath: String
        /// Validity of the signed URL in seconds (typically 60).
        let expiresIn: Int
}
