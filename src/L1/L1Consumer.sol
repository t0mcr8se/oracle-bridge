// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL1T1Messenger} from "@t1/L1/IL1T1Messenger.sol";
import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
// import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract L1Consumer is FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;
    

    // chainlink router address
    // ChainLinkRouter on Sepolia at: 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0 
    address public chainlinkRouter;
    // chainlink donId for the L1 chain
    // (eth sepolia DonID: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000)
    address public donId;
    // t1 canonical bridge
    IL1T1Messenger public messenger;
    // l2ChainId to be used on the canonical bridge calls
    uint64 public l2ChainId;
    uint256 public gasLimit; 
    // chainlink functions consumer address on L2
    address public l2Consumer;
    
    // to generalize this L1Consumer we can make the l2Consumer as a mapping, using a single consumer for demo purpose
    // mapping (address => boolean) l2Consumers;

    // store the last request ID, response, and error
    // TODO: replace with struct and mapping to support non sequential requests
    bytes32 public lastRequestId;
    bytes public lastResponse;
    bytes public lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);

    // The response here is not parsed, l2Consumers can have special parsing logic depending on their 
    event Response(
        bytes32 indexed requestId,
        bytes response,
        bytes err
    );


    constructor(
        address _chainlinkRouter, 
        address _messenger, 
        address _l2Consumer, 
        uint64 _l2ChainId, 
        uint256 _gasLimit
        ) FunctionsClient(_chainlinkRouter) {
        chainlinkRouter = _chainlinkRouter;
        messenger = IL1T1Messenger(_messenger);
        l2Consumer = _l2Consumer;
        l2ChainId = _l2ChainId;
        gasLimit = _gasLimit;
    }

    // function handleRequestFromL2(string calldata query, address user) external {
    // }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        if (lastRequestId != requestId) {
            revert UnexpectedRequestID(requestId); // Check if request IDs match
        }
        // Update the contract's state variables with the response and any errors
        lastResponse = response;
        lastError = err;

        // Emit an event to log the response
        emit Response(requestId, lastResponse, lastError);
    }
}
