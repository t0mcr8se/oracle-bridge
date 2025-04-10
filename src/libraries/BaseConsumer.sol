// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { IBaseConsumer } from "./IBaseConsumer.sol";
import { ConfirmedOwner } from "@chainlink/contracts/v0.8/shared/access/ConfirmedOwner.sol";
import { IT1Messenger } from "@t1/libraries/IT1Messenger.sol";

/// @title BaseConsumer
/// @notice Abstract base contract for cross-chain consumers that send/receive messages across domains using a messenger.
/// @dev Implements ownership checks, x-domain verification, and consumer initialization guard.
abstract contract BaseConsumer is IBaseConsumer, ConfirmedOwner {

    /// @notice Address of the T1 cross-chain messenger contract.
    address public immutable messenger;
    
    /// @notice Chain ID of the cross-domain (external) chain.
    uint64 public immutable xChainId;

    /// @notice Address of the cross-domain consumer contract (on the other chain).
    address public xDomainConsumer;

    /// @notice Constructs the BaseConsumer contract.
    /// @param _xChainId Chain ID of the other domain (L1 or L2).
    /// @param _messenger Address of the cross-domain messenger contract.
    constructor(uint64 _xChainId, address _messenger) ConfirmedOwner(msg.sender) {
        xChainId = _xChainId;
        messenger = _messenger;
    }

    /// @notice Modifier that restricts function calls to the cross-domain consumer.
    /// @dev Uses the messenger to verify that the message sender matches the expected xDomainConsumer.
    modifier onlyXDomainConsumer() {
        address sender = IT1Messenger(messenger).xDomainMessageSender();
        if (sender != xDomainConsumer) {
            revert UnauthorizedCaller(sender);
        }
        _;
    }

    /// @notice Modifier that ensures the cross-domain consumer address has been initialized.
    modifier consumerInitialized() {
        if (xDomainConsumer == address(0)) {
            revert ConsumerNotInitialized();
        }
        _;
    }

    /// @notice Sets the address of the cross-domain consumer contract.
    /// @dev Only callable by the contract owner.
    /// @param _xDomainConsumer The address of the consumer contract on the other chain.
    function setXDomainConsumer(address _xDomainConsumer) external onlyOwner {
        xDomainConsumer = _xDomainConsumer;
    }
}
