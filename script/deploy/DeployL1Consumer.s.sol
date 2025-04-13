// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";

import { DeploymentUtils } from "lib/t1/contracts/script/lib/DeploymentUtils.sol";
import { L1Consumer } from "../../src/L1/L1Consumer.sol";

// solhint-disable var-name-mixedcase

contract DeployL2Consumer is Script, DeploymentUtils {
    uint256 private L1_DEPLOYER_PRIVATE_KEY = vm.envUint("L1_DEPLOYER_PRIVATE_KEY");
    uint64 private T1_L2_CHAIN_ID = uint64(vm.envUint("T1_L2_CHAIN_ID"));
    address private L1_T1_MESSENGER_PROXY_ADDR = vm.envAddress("L1_T1_MESSENGER_PROXY_ADDR");
    address private CHAINLINK_L1_ROUTER_ADDR = vm.envAddress("CHAINLINK_L1_ROUTER_ADDR");
    bytes32 private CHAINLINK_DON_ID = vm.envBytes32("CHAINLINK_DON_ID");
    uint64 private CHAINLINK_SUBSCRIPTION_ID = uint64(vm.envUint("CHAINLINK_SUBSCRIPTION_ID"));

    L1Consumer private l1Consumer;

    function run() external {
        logStart("DeployL1Consumer");
        vm.startBroadcast(L1_DEPLOYER_PRIVATE_KEY);

        deployL1Consumer();

        vm.stopBroadcast();
        logEnd("DeployL1Consumer");
    }

    function deployL1Consumer() internal {
        l1Consumer = new L1Consumer(
            CHAINLINK_L1_ROUTER_ADDR,
            L1_T1_MESSENGER_PROXY_ADDR,
            T1_L2_CHAIN_ID,
            CHAINLINK_SUBSCRIPTION_ID,
            CHAINLINK_DON_ID
        );

        logAddress("L1_CONSUMER_ADDR", address(l1Consumer));
    }
}
