// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

/// @title IL1Consumer
/// @notice Interface for the L1Consumer contract that bridges Chainlink Functions requests from L2 to L1,
/// processes them using Chainlink DONs, and returns the result to the L2 consumer.
/// @dev This interface defines the expected events, errors, and external functions of L1Consumer.
interface IL1Consumer {
    /// @notice Emitted when a Chainlink Functions request is successfully initiated.
    /// @param l1RequestId The ID of the request on L1 (Chainlink Functions).
    /// @param l2RequestId The ID of the original request from L2.
    event Request(bytes32 indexed l1RequestId, bytes32 indexed l2RequestId);

    /// @notice Emitted when a Chainlink Functions request is fulfilled.
    /// @param l1RequestId The ID of the request on L1.
    /// @param l2RequestId The ID of the original request from L2.
    /// @param response The raw response bytes returned from Chainlink Functions.
    /// @param err The error data (if any) returned from Chainlink Functions.
    event Response(bytes32 indexed l1RequestId, bytes32 indexed l2RequestId, bytes response, bytes err);

    /// @notice Thrown when a callback is received for an unrecognized L1 request ID.
    /// @param requestId The unrecognized L1 request ID.
    error UnexpectedRequestID(bytes32 requestId);

    /// @notice Thrown when an L2 request is submitted multiple times.
    /// @param l2RequestId The duplicate L2 request ID.
    error DuplicateL2RequestID(bytes32 l2RequestId);

    /// @notice Submits a request to Chainlink Functions on L1 based on a request from L2.
    /// @dev Only callable by the designated cross-domain consumer.
    /// @param source The JavaScript source code to run via Chainlink Functions.
    /// @param args The arguments to be passed to the JavaScript code.
    /// @param l2RequestId The request ID as assigned by the L2 consumer.
    /// @param gasLimit The maximum gas to be used for the Chainlink Functions request.
    /// @return l1RequestId The resulting L1 request ID created on Chainlink Functions.
    function handleRequest(string calldata source, string[] calldata args, bytes32 l2RequestId, uint32 gasLimit)
        external
        returns (bytes32 l1RequestId);
}
