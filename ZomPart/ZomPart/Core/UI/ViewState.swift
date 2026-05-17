import Foundation

enum ViewState<Content: Equatable>: Equatable {
    case idle
    case loading
    case loaded(Content)
    case empty
    case error(String)
}
