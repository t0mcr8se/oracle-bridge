// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IL2Consumer {
    /// @notice Emitted when a response from L1 is received
    /// @param requestId The ID of the original request
    /// @param response The raw response bytes returned by Chainlink
    /// @param err Any error returned by the Chainlink function
    event Response(bytes32 indexed requestId, bytes response, bytes err);

    /// @notice Emitted when a new off-chain request is sent to L1
    /// @param requestId The locally generated L2 request ID
    /// @param source The JavaScript source code for the Chainlink request
    /// @param args The arguments provided to the Chainlink function
    event RequestSent(bytes32 requestId, string source, string[] args);

    /// @notice Thrown when an unknown request ID is received from L1
    /// @param requestId The unexpected or untracked request ID
    error UnexpectedRequestID(bytes32 requestId);

    /// @notice Sends a payload from L2 to L1 for processing with Chainlink
    /// @param source The JavaScript code that defines the Chainlink request
    /// @param args The arguments for the Chainlink request
    /// @param gasLimit The gas limit for the request execution on L1
    /// @return requestId The unique ID generated for the request
    function sendPayload(
        string calldata source,
        string[] calldata args,
        uint32 gasLimit
    )
        external
        returns (bytes32 requestId);

    /// @notice Handles the response returned from L1 Chainlink Functions request
    /// @param requestId The original request ID sent from L2
    /// @param response The raw result returned by Chainlink Functions
    /// @param err Any error encountered during the off-chain request
    function handleResponse(bytes32 requestId, bytes calldata response, bytes calldata err) external;
}
