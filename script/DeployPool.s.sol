// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { Script } from "../lib/forge-std/src/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { AMMPool } from '../src/AMMPool.sol';

contract DeployPool is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PV_KEY");

        address tokenA = vm.envAddress("TOKEN_A_ADDRESS"); // Address of Token A
        address tokenB = vm.envAddress("TOKEN_B_ADDRESS"); // Address of Token B

        vm.startBroadcast(deployerPrivateKey);

        AMMPool pool = new AMMPool(tokenA, tokenB);

        console.log("AMM Pool created at address: ", address(pool));

        vm.stopBroadcast();
    }
}