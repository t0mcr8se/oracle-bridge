// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";

import { IBaseConsumer } from "../../src/libraries/IBaseConsumer.sol";

// solhint-disable var-name-mixedcase

contract DeployL2Consumer is Script {
    uint256 private L1_DEPLOYER_PRIVATE_KEY = vm.envUint("L1_DEPLOYER_PRIVATE_KEY");
    // address private L1_CONSUMER_ADDR = vm.envAddress(name);
    address private L1_CONSUMER_ADDR = vm.envAddress("L1_CONSUMER_ADDR");
    address private L2_CONSUMER_ADDR = vm.envAddress("L2_CONSUMER_ADDR");

    function run() external {
        // logStart("DeployL1Consumer");
        vm.startBroadcast(L1_DEPLOYER_PRIVATE_KEY);

        IBaseConsumer(L1_CONSUMER_ADDR).setXDomainConsumer(L2_CONSUMER_ADDR);

        vm.stopBroadcast();
    }
}
