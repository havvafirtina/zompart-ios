//
//  VehicleRepository.swift
//  ZomPart
//
//  Created by Havva Fırtına on 2026-05-16.
//

import Foundation
import SBNetworking

/// Concrete repository that talks to the Supabase vehicle-resolve edge function.
/// Uses `actor` isolation to satisfy `Sendable`.
actor VehicleRepository: VehicleRepositoryProtocol {

    private let client: HTTPClient

    init(client: HTTPClient) {
        self.client = client
    }

    // MARK: - Garage

    func listVehicles() async throws -> [VehicleDomain] {
        do {
            let envelope = try await client.submitRequest(request: VehicleListRequest())
            guard let envelope, envelope.success, envelope.data != nil else { throw VehicleError.emptyResponse }
            return envelope.toModel().vehicles
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as VehicleError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapCommonError(httpError)
        } catch {
            throw VehicleError.unknown
        }
    }

    // MARK: - Resolve

    func resolveByVIN(_ vin: String, countryCode: String) async throws -> VehicleResolveResultDomain {
        let request = VehicleResolveVINRequest(vin: vin, countryCode: countryCode)
        return try await resolveAndExtract(request: request, on400: .invalidVIN)
    }

    func resolveByPlate(_ plate: String, countryCode: String) async throws -> VehicleResolveResultDomain {
        let request = VehicleResolvePlateRequest(plate: plate, countryCode: countryCode)
        return try await resolveAndExtract(request: request, on400: .invalidPlate)
    }

    // MARK: - Private helpers

    private func resolveAndExtract<R: RequestProtocol>(
        request: R,
        on400 error400: VehicleError
    ) async throws -> VehicleResolveResultDomain
    where R.EndpointType.ResponseType == APIEnvelope<VehicleResolveDataDTO> {
        do {
            let envelope = try await client.submitRequest(request: request)
            guard let envelope, envelope.success, envelope.data != nil else { throw VehicleError.emptyResponse }
            let response = envelope.toModel()
            guard let vehicle = response.vehicles.first else { throw VehicleError.vehicleNotFound }
            let isNew = response.resolution?.isNew ?? true
            return VehicleResolveResultDomain(vehicle: vehicle, isNew: isNew)
        } catch is CancellationError {
            throw CancellationError()
        } catch let urlError as URLError where urlError.code == .cancelled {
            throw CancellationError()
        } catch let error as VehicleError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapResolveError(httpError, on400: error400)
        } catch {
            throw VehicleError.unknown
        }
    }

    // MARK: - Error mapping

    private static func mapResolveError(_ error: HTTPClientError, on400 error400: VehicleError) -> VehicleError {
        switch error {
        case .notFound: return .vehicleNotFound
        case .serverError: return .providerUnavailable
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidVIN: return .invalidVIN
            case .invalidPlate: return .invalidPlate
            case .invalidCountryCode: return .invalidCountryCode
            default: return error400
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapCommonError(_ error: HTTPClientError) -> VehicleError {
        switch error {
        case .notFound: return .vehicleNotFound
        case .serverError: return .providerUnavailable
        case .clientError(statusCode: 429, _): return .rateLimitExceeded
        case .clientError(_, let data):
            switch APIErrorParser.code(from: data) {
            case .invalidVIN: return .invalidVIN
            case .invalidPlate: return .invalidPlate
            case .invalidCountryCode: return .invalidCountryCode
            default: return .unknown
            }
        case .unauthorized: return .tokenExpired
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
