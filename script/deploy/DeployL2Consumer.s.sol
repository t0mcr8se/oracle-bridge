// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";

import { DeploymentUtils } from "lib/t1/contracts/script/lib/DeploymentUtils.sol";
import { L2Consumer } from "../../src/L2/L2Consumer.sol";

// solhint-disable var-name-mixedcase

contract DeployL2Consumer is Script, DeploymentUtils {
    uint256 private L2_DEPLOYER_PRIVATE_KEY = vm.envUint("L2_DEPLOYER_PRIVATE_KEY");
    address private L2_T1_MESSENGER_PROXY_ADDR = vm.envAddress("L2_T1_MESSENGER_PROXY_ADDR");
    uint64 private T1_L1_CHAIN_ID = uint64(vm.envUint("T1_L1_CHAIN_ID"));

    L2Consumer private l2Consumer;

    function run() external {
        logStart("DeployL2Consumer");
        vm.startBroadcast(L2_DEPLOYER_PRIVATE_KEY);

        deployL2Consumer();

        vm.stopBroadcast();
        logEnd("DeployL2Consumer");
    }

    function deployL2Consumer() internal {
        l2Consumer = new L2Consumer(L2_T1_MESSENGER_PROXY_ADDR, T1_L1_CHAIN_ID);

        logAddress("L2_CONSUMER_ADDR", address(l2Consumer));
    }
}
