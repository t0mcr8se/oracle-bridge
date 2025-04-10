// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL1T1Messenger} from "@t1/L1/IL1T1Messenger.sol";
import {IL1Consumer} from "./IL1Consumer.sol";
import {IL2Consumer} from "../L2/IL2Consumer.sol";
import {FunctionsClient} from "@chainlink/contracts/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";

contract L1Consumer is FunctionsClient, IL1Consumer, ConfirmedOwner {
    using FunctionsRequest for FunctionsRequest.Request;

    // Constants
    bytes32 public constant BYTES32_ZERO = bytes32(0);
    /// @notice chainlink router address
    address public immutable chainlinkRouter;
    /// @notice chainlink donId for the L1 chain
    bytes32 public immutable donId;
    /// @notice t1 canonical bridge
    IL1T1Messenger public immutable messenger;
    /// @notice l2ChainId to be used on the canonical bridge calls
    uint64 public immutable l2ChainId;
    
    
    /// @notice chainlink functions subscriptionId
    uint64 public subscriptionId;
    /// @notice chainlink functions consumer address on L2
    address public l2Consumer;

    /// @notice maps l2 RequestId to l1 Request Id
    mapping (bytes32 l2RequestId => bytes32 l1RequestId) l2RequestIds;
    /// @notice maps l1 RequestId to l2 Request Id
    mapping (bytes32 l1RequestId => bytes32 l2RequestId) l1RequestIds;
    
    /**
        @dev to generalize this L1Consumer we can make the l2Consumer as a mapping,
        using a single consumer for demo purpose
        mapping (address => boolean) l2Consumers;
        Can add subscriptionId control here if we have multiple consumers also
        mapping (address => uint64) subscriptionId;
     */
    

    // TODO: replace with struct and mapping to support non sequential requests
    /// @notice the last request ID, response, and error
    // bytes32 public lastRequestId;
    // bytes public lastResponse;
    // bytes public lastError;

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);
    error UnauthorizedCaller(address caller);
    error DuplicateL2RequestID(bytes32 l2RequestId);
    error ConsumerNotInitialized();

    // The response here is not parsed, l2Consumers can have special parsing logic depending on their 
    // TODO: natspecs docstring
    event Response(
        bytes32 indexed l1RequestId,
        bytes32 indexed l2RequestId,
        bytes response,
        bytes err
    );
    event Request(
        bytes32 indexed l1RequestId,
        bytes32 indexed l2RequestId
    );

    // TODO: natspecs docstring
    constructor(
        address _chainlinkRouter, 
        address _messenger, 
        uint64 _l2ChainId, 
        uint64 _subscriptionId,
        bytes32 _donId
    ) FunctionsClient(_chainlinkRouter) ConfirmedOwner(msg.sender) {
        chainlinkRouter = _chainlinkRouter;
        messenger = IL1T1Messenger(_messenger);
        l2ChainId = _l2ChainId;
        subscriptionId = _subscriptionId;
        donId = _donId;
    }

    // TODO: natspecs docstring
    modifier onlyXDomainConsumer() {
        address sender = messenger.xDomainMessageSender();
        if(sender != l2Consumer){
            revert UnauthorizedCaller(sender);
        }
        _;
    }
    
    modifier consumerInitialized() {
        if(l2Consumer == address(0)){
            revert ConsumerNotInitialized();
        }
        _;
    }

    // Chicken or Egg came first??/?/1
    // TODO: natspecs docstring
    function setL2Consumer(address _l2Consumer) external onlyOwner {
        l2Consumer = _l2Consumer;
    }

    // TODO: natspec docstring
    // function setSubscriptionId(uint64 _subscriptionId) external onlyOwner {
    //     subscriptionId = _subscriptionId;
    // }

    // TODO: natspec docstring or inherit doc
    function handleRequest(
        string calldata source, 
        string [] calldata args, 
        bytes32 l2RequestId,
        uint32 gasLimit
    ) external consumerInitialized onlyXDomainConsumer returns (bytes32 l1RequestId) {
        if(l2RequestIds[l2RequestId] != BYTES32_ZERO){
            // Making sure the message wasn't double sent
            // TODO: here we can send an error message via the bridge to the l2Consumer
            // so it can know that the request has failed
            revert DuplicateL2RequestID(l2RequestId);
        }

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source); // Initialize the request with JS code
        if (args.length > 0) req.setArgs(args); // Set the arguments for the request

        l1RequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donId
        );
        
        l2RequestIds[l2RequestId] = l1RequestId;
        l1RequestIds[l1RequestId] = l2RequestId;
        
        // TODO: could send the l1 Request Id to L2 Consumer as an ack

        emit Request(l1RequestId, l2RequestId);
        return l1RequestId;
    }

    /**
     * @notice Callback function for fulfilling a request
     * @param requestId The ID of the request to fulfill
     * @param response The HTTP response data
     * @param err Any errors from the Functions request
     */
     // TODO: inherit docstring from chainlink
    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory err
    ) internal override {
        bytes32 l2RequestId = l1RequestIds[requestId];
        if (l2RequestId == BYTES32_ZERO) {
            revert UnexpectedRequestID(requestId); // Check if request ID exists
        }
        
        // encode handleResponse call and send it to l2consumer via canonical brige
        bytes memory message = abi.encodeWithSelector(
            IL2Consumer.handleResponse.selector,
            l2RequestId, 
            response, 
            err
        );
        messenger.sendMessage(
            l2Consumer,
            0,
            message,
            2000000, // TODO: store gasLimit and use here instead of hardcoded
            l2ChainId
        );

        // emit an event to log the response
        emit Response(requestId, l2RequestId, response, err);
    }
}
