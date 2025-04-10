// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

interface IBaseConsumer {
    /// @notice Sets the address of the cross-domain consumer (on the other chain).
    /// @dev Only callable by the contract owner.
    /// @param _xDomainConsumer The address of the consumer contract on the other chain.
    function setXDomainConsumer(address _xDomainConsumer) external;

    /// @notice Returns the currently set cross-domain consumer address.
    function xDomainConsumer() external view returns (address);

    /// @notice Returns the address of the cross-domain messenger used to verify messages.
    function messenger() external view returns (address);

    /// @notice Chain ID of the cross-domain (external) chain.
    function xChainId() external view returns (uint64);

    /// @notice Error thrown when a message sender is not the expected cross-domain consumer.
    /// @param caller The unauthorized sender address.
    error UnauthorizedCaller(address caller);

    /// @notice Error thrown when trying to access or use the cross-domain consumer before it's initialized.
    error ConsumerNotInitialized();
}
