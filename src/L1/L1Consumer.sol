// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IL1Consumer } from "./IL1Consumer.sol";
import { IL2Consumer } from "../L2/IL2Consumer.sol";
import { BaseConsumer } from "../libraries/BaseConsumer.sol";
import { IT1Messenger } from "@t1/libraries/IT1Messenger.sol";
import { FunctionsClient } from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import { FunctionsRequest } from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import { ConfirmedOwner } from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";

/// @title L1Consumer
/// @notice Consumes cross-chain requests from L2, invokes Chainlink Functions on L1, and sends results back to L2.
/// @dev Inherits from Chainlink FunctionsClient and custom BaseConsumer. Expects cross-chain messages via IT1Messenger.
contract L1Consumer is IL1Consumer, BaseConsumer, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    /// @notice A zero-value placeholder used to validate uninitialized request IDs
    bytes32 public constant BYTES32_ZERO = bytes32(0);

    /// @notice chainlink functions donId for the current chain
    bytes32 public immutable donId;

    /// @notice Chainlink Functions subscription ID used to fund requests
    uint64 public subscriptionId;

    /// @notice Maps L2 request IDs to their corresponding L1 request IDs
    mapping(bytes32 l2RequestId => bytes32 l1RequestId) l2RequestIds;

    /// @notice Maps L1 request IDs to their originating L2 request IDs
    mapping(bytes32 l1RequestId => bytes32 l2RequestId) l1RequestIds;

    /// @notice Creates a new L1Consumer contract
    /// @param _chainlinkRouter The address of the Chainlink Functions router contract
    /// @param _messenger The address of the cross-domain messenger on L1
    /// @param _l2ChainId The L2 chain ID this contract is communicating with
    /// @param _subscriptionId The Chainlink Functions billing subscription ID
    /// @param _donId The DON ID representing the Chainlink oracle network on L1
    constructor(
        address _chainlinkRouter,
        address _messenger,
        uint64 _l2ChainId,
        uint64 _subscriptionId,
        bytes32 _donId
    )
        FunctionsClient(_chainlinkRouter)
        BaseConsumer(_l2ChainId, _messenger)
    {
        subscriptionId = _subscriptionId;
        donId = _donId;
    }

    /// @inheritdoc IL1Consumer
    function handleRequest(
        string calldata source,
        string[] calldata args,
        bytes32 l2RequestId,
        uint32 gasLimit
    )
        external
        consumerInitialized
        onlyXDomainConsumer
        returns (bytes32 l1RequestId)
    {
        if (l2RequestIds[l2RequestId] != BYTES32_ZERO) {
            revert DuplicateL2RequestID(l2RequestId);
        }

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);

        if (args.length > 0) {
            req.setArgs(args);
        }

        l1RequestId = _sendRequest(req.encodeCBOR(), subscriptionId, gasLimit, donId);

        l2RequestIds[l2RequestId] = l1RequestId;
        l1RequestIds[l1RequestId] = l2RequestId;

        emit Request(l1RequestId, l2RequestId);
        return l1RequestId;
    }

    /// @inheritdoc FunctionsClient
    /// @notice When the ChainLink DON calls this function,
    /// we send a the response in a message to the consumer contract on L2
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        bytes32 l2RequestId = l1RequestIds[requestId];
        if (l2RequestId == BYTES32_ZERO) {
            revert UnexpectedRequestID(requestId);
        }

        bytes memory message = abi.encodeWithSelector(IL2Consumer.handleResponse.selector, l2RequestId, response, err);

        IT1Messenger(messenger).sendMessage(
            xDomainConsumer,
            0,
            message,
            2_000_000, // TODO: Use stored gasLimit for each request if dynamic
            xChainId
        );

        emit Response(requestId, l2RequestId, response, err);
    }
}
