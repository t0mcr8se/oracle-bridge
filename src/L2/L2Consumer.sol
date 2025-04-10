// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {IL2T1Messenger} from "@t1/L2/IL2T1Messenger.sol";
import {IL2Consumer} from "./IL2Consumer.sol";
import {IL1Consumer} from "../L1/IL1Consumer.sol";
import {ConfirmedOwner} from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";


contract L2Consumer is IL2Consumer, ConfirmedOwner {
    
    /// @notice t1 canonical bridge on L2 side
    IL2T1Messenger public immutable messenger;

    /// @notice L1 ChainId to be used on the canonical bridge calls
    uint64 public immutable l1ChainId;

    /// @notice chainlink functions consumer (handler) address on L1
    address public l1Consumer;
    
    mapping (address whitelistedAddress => bool isWhitelisted) whitelist;

    // mapping (bytes32 l2RequestId => boolean);

    // Custom error type
    error UnexpectedRequestID(bytes32 requestId);
    error UnauthorizedCaller(address caller);
    error ConsumerNotInitialized();

    /// @dev The `response` here is not parsed, 
    event Response(
        bytes32 indexed requestId,
        bytes response,
        bytes err
    );
    event RequestSent(
        bytes32 requestId,
        string source,
        string [] args
    );

    constructor(
        address _messenger, 
        uint64 _l1ChainId
    ) ConfirmedOwner(msg.sender) {
        messenger = IL2T1Messenger(_messenger);
        l1ChainId = _l1ChainId;
        whitelist[msg.sender] = true;
    }

    modifier onlyXDomainConsumer() {
        address sender = messenger.xDomainMessageSender();
        if(sender != l1Consumer){
            revert UnauthorizedCaller(sender);
        }
        _;
    }

    modifier consumerInitialized() {
        if(l1Consumer == address(0)){
            revert ConsumerNotInitialized();
        }
        _;
    }

    modifier onlyWhiteList() {
        if(!whitelist[msg.sender]){
            revert UnauthorizedCaller(msg.sender);
        }
        _;
    }

    function setL1Consumer(address _l1Consumer) external onlyOwner {
        l1Consumer = _l1Consumer;
    }

    function addToWhiteList(address a) external onlyOwner {
        whitelist[a] = true;
    }

    function sendPayload (
        string calldata source, 
        string [] calldata args, 
        uint32 gasLimit
    ) external onlyWhiteList consumerInitialized returns (bytes32 requestId) {
        requestId = keccak256(abi.encodePacked(source, block.timestamp));


        bytes memory message = abi.encodeWithSelector(
            IL1Consumer.handleRequest.selector,
            source,
            args,
            requestId,
            gasLimit
        );

        messenger.sendMessage(
            l1Consumer,
            0,
            message,
            gasLimit,
            l1ChainId
        );

        emit RequestSent(
            requestId,
            source, 
            args
        );

        return requestId;
    }

    function handleResponse(
        bytes32 requestId, 
        bytes memory response, 
        bytes memory err
    ) external onlyXDomainConsumer {
        // TODO: decode response and do something onchain with the result
        // example: TVL API response
        emit Response(requestId, response, err);
    }
}
