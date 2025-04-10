// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IFunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/interfaces/IFunctionsClient.sol";

interface IL1Consumer  {
    /// @notice Called by L2 to request Chainlink Functions from L1.
    /// @param source The source code payload, such as a js snippet or query or external API parameters.
    /// @param args The parameters for the function execution.
    function handleRequest(string calldata source, string[] calldata args, bytes32 l2RequestId, uint32 gasLimit) external returns (bytes32 requestId);
}