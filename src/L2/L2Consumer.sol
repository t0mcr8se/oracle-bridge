// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {BaseConsumer} from "../libraries/BaseConsumer.sol";
import {IL2Consumer} from "./IL2Consumer.sol";
import {IL1Consumer} from "../L1/IL1Consumer.sol";
import {IT1Messenger} from "@t1/libraries/IT1Messenger.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";

/// @title L2Consumer
/// @notice This contract is responsible for sending off-chain requests to the L1 consumer and handling responses.
contract L2Consumer is IL2Consumer, BaseConsumer {
    /// @notice Mapping to track whitelisted addresses that can interact with the contract
    mapping(address whitelistedAddress => bool isWhitelisted) whitelist;

    /// @notice Constructor to initialize the contract with the L1 Chain ID and the messenger address.
    /// @param _messenger The address of the messenger contract for cross-domain communication
    /// @param _l1ChainId The L1 chain ID for cross-domain messaging
    constructor(address _messenger, uint64 _l1ChainId) BaseConsumer(_l1ChainId, _messenger) {
        whitelist[msg.sender] = true; // Add the deployer to the whitelist
    }

    /// @notice Modifier that restricts access to whitelisted addresses only.
    modifier onlyWhiteList() {
        if (!whitelist[msg.sender]) {
            revert UnauthorizedCaller(msg.sender); // Revert if the caller is not whitelisted
        }
        _;
    }

    /// @notice Adds a new address to the whitelist.
    /// @param a The address to be added to the whitelist
    function addToWhiteList(address a) external onlyOwner {
        whitelist[a] = true; // Add the address to the whitelist
    }

    /// @inheritdoc IL2Consumer
    function sendPayload(string calldata source, string[] calldata args, uint32 gasLimit)
        external
        onlyWhiteList
        consumerInitialized
        returns (bytes32 requestId)
    {
        requestId = keccak256(abi.encodePacked(source, block.timestamp)); // Generate a unique request ID

        // Encode the message to send to L1
        bytes memory message =
            abi.encodeWithSelector(IL1Consumer.handleRequest.selector, source, args, requestId, gasLimit);

        // Send the message to L1 using the messenger
        IT1Messenger(messenger).sendMessage(xDomainConsumer, 0, message, gasLimit, xChainId);

        emit RequestSent(requestId, source, args);

        return requestId; // Return the request ID
    }

    /// @inheritdoc IL2Consumer
    function handleResponse(bytes32 requestId, bytes memory response, bytes memory err) external onlyXDomainConsumer {
        // TODO: Decode response and process it on-chain (example: TVL API response)

        emit Response(requestId, response, err); // Emit the response event
    }
}
