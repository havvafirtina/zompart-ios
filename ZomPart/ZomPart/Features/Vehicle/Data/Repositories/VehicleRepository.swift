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
            guard let envelope else { throw VehicleError.emptyResponse }
            return envelope.toModel().vehicles
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

    func resolveByPersonNumber(_ personNumber: String, countryCode: String) async throws -> VehicleResolveResultDomain {
        let request = VehicleResolvePersonRequest(personNumber: personNumber, countryCode: countryCode)
        return try await resolveAndExtract(request: request, on400: .invalidCountryCode)
    }

    func resolveByOrganizationNumber(_ orgNumber: String, countryCode: String) async throws -> VehicleResolveResultDomain {
        let request = VehicleResolveCompanyRequest(organizationNumber: orgNumber, countryCode: countryCode)
        return try await resolveAndExtract(request: request, on400: .invalidCountryCode)
    }

    // MARK: - Manual flow

    func fetchManualSession() async throws -> VehicleManualSessionDomain? {
        do {
            let envelope = try await client.submitRequest(request: VehicleManualLookupRequest())
            guard let envelope else { throw VehicleError.emptyResponse }
            let response = envelope.toModel()
            return Self.extractSession(from: response.resolution)
        } catch let error as VehicleError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapCommonError(httpError)
        } catch {
            throw VehicleError.unknown
        }
    }

    func submitManualStep(
        _ value: VehicleManualStepValueDomain,
        sessionId: String?,
        countryCode: String
    ) async throws -> VehicleManualResultDomain {
        do {
            let endpoint = VehicleManualStepEndpoint(value: value, sessionId: sessionId, countryCode: countryCode)
            let envelope = try await client.submitRequest(endpoint: endpoint)
            guard let envelope else { throw VehicleError.emptyResponse }
            let response = envelope.toModel()

            if let vehicle = response.vehicles.first,
               response.resolution?.isResolved == true {
                let isNew = response.resolution?.isNew ?? true
                return .resolved(VehicleResolveResultDomain(vehicle: vehicle, isNew: isNew))
            }

            guard let session = Self.extractSession(from: response.resolution) else {
                throw VehicleError.emptyResponse
            }
            return .inProgress(session)
        } catch let error as VehicleError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapManualError(httpError)
        } catch {
            throw VehicleError.unknown
        }
    }

    // MARK: - Private helpers

    private func resolveAndExtract<R: RequestProtocol>(
        request: R,
        on400 error400: VehicleError
    ) async throws -> VehicleResolveResultDomain
    where R.EndpointType.ResponseType == APIEnvelope<VehicleResolveDataDTO> {
        do {
            let envelope = try await client.submitRequest(request: request)
            guard let envelope else { throw VehicleError.emptyResponse }
            let response = envelope.toModel()
            guard let vehicle = response.vehicles.first else { throw VehicleError.vehicleNotFound }
            let isNew = response.resolution?.isNew ?? true
            return VehicleResolveResultDomain(vehicle: vehicle, isNew: isNew)
        } catch let error as VehicleError {
            throw error
        } catch let httpError as HTTPClientError {
            throw Self.mapResolveError(httpError, on400: error400)
        } catch {
            throw VehicleError.unknown
        }
    }

    private static func extractSession(from resolution: VehicleResolutionDTO?) -> VehicleManualSessionDomain? {
        guard let r = resolution,
              !r.isResolved,
              let sessionId = r.sessionId,
              let nextStepRaw = r.nextStep,
              let nextStep = VehicleManualStepDomain(rawValue: nextStepRaw) else {
            return nil
        }
        return VehicleManualSessionDomain(
            sessionId: sessionId,
            nextStep: nextStep,
            nextStepIsOptional: r.nextStepIsOptional ?? nextStep.isOptional,
            options: r.options ?? [],
            completedSteps: (r.completedSteps ?? []).map { $0.toModel() }
        )
    }

    // MARK: - Error mapping

    private static func mapResolveError(_ error: HTTPClientError, on400 error400: VehicleError) -> VehicleError {
        switch error {
        case .clientError(statusCode: 400): return error400
        case .clientError(statusCode: 404): return .vehicleNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .clientError(statusCode: 503): return .providerUnavailable
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapCommonError(_ error: HTTPClientError) -> VehicleError {
        switch error {
        case .clientError(statusCode: 400): return .invalidVIN
        case .clientError(statusCode: 404): return .vehicleNotFound
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .clientError(statusCode: 503): return .providerUnavailable
        case .clientError:                  return .invalidVIN
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }

    private static func mapManualError(_ error: HTTPClientError) -> VehicleError {
        switch error {
        case .clientError(statusCode: 400): return .invalidStep
        case .clientError(statusCode: 429): return .rateLimitExceeded
        case .clientError(statusCode: 503): return .providerUnavailable
        case .notConnectedToInternet, .networkConnectionLost: return .network
        default: return .unknown
        }
    }
}
