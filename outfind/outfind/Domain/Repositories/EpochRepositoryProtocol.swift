import Foundation

/// Repository protocol for epoch operations
protocol EpochRepositoryProtocol: Sendable {
    /// Fetch epochs with optional filtering
    /// - Parameter filter: Optional filter criteria
    /// - Returns: Array of epochs matching the filter
    func fetchEpochs(filter: EpochFilter?) async throws -> [Epoch]

    /// Fetch a single epoch by ID
    /// - Parameter id: Epoch ID
    /// - Returns: The epoch
    func fetchEpoch(id: UInt64) async throws -> Epoch

    /// Fetch current epoch state from chain
    /// - Parameter id: Epoch ID
    /// - Returns: Current epoch state
    func fetchEpochState(id: UInt64) async throws -> EpochState

    /// Fetch epoch capability from chain
    /// - Parameter id: Epoch ID
    /// - Returns: Epoch capability level
    func fetchEpochCapability(id: UInt64) async throws -> EpochCapability

    /// Subscribe to epoch updates
    /// - Parameter id: Epoch ID
    /// - Returns: Async stream of epoch updates
    func subscribeToEpochEvents(id: UInt64) -> AsyncStream<EpochEvent>

    /// Unsubscribe from epoch events
    /// - Parameter id: Epoch ID
    func unsubscribeFromEpochEvents(id: UInt64) async
}

// MARK: - Filter

/// Filter criteria for fetching epochs
struct EpochFilter: Sendable {
    /// Filter by epoch states
    let states: Set<EpochState>?

    /// Filter by capability level
    let minCapability: EpochCapability?

    /// Filter by location (within radius)
    let location: EpochLocation?

    /// Filter by tags
    let tags: [String]?

    /// Maximum number of results
    let limit: Int?

    /// Offset for pagination
    let offset: Int?

    init(
        states: Set<EpochState>? = nil,
        minCapability: EpochCapability? = nil,
        location: EpochLocation? = nil,
        tags: [String]? = nil,
        limit: Int? = nil,
        offset: Int? = nil
    ) {
        self.states = states
        self.minCapability = minCapability
        self.location = location
        self.tags = tags
        self.limit = limit
        self.offset = offset
    }
}

// MARK: - Events

/// Epoch-related events
enum EpochEvent: Equatable, Sendable {
    /// Epoch phase changed
    case phaseChanged(EpochState)

    /// Participant count changed
    case participantCountChanged(UInt64)

    /// Timer tick with time remaining
    case timerTick(timeRemaining: TimeInterval)

    /// Epoch has closed
    case closed

    /// Epoch has been finalized
    case finalized

    /// Error occurred
    case error(String)
}
