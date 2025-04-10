// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IL2Consumer {
    /// @notice Triggers a request to L1 for off-chain computation via Chainlink Functions.
    /// @param source The query or data to be sent to Chainlink Functions on L1.
    /// @param gasLimit The amount of gas to provide for the L1 call.
    function sendPayload(string calldata source, string [] calldata args, uint32 gasLimit) external returns (bytes32 requestId);

    /// @notice Handles the response bridged back from L1.
    /// @param response The data returned from Chainlink Functions.
    function handleResponse(bytes32 requestId, bytes memory response, bytes memory err) external;
}
