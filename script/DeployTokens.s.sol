// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { Script } from "../lib/forge-std/src/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { TestERC20 } from '../src/TestERC20.sol';

contract DeployTokens is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PV_KEY");
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS"); 

        string memory tokenAName = "Test Dollar";
        string memory tokenASymbol = "USD";
        string memory tokenBName = "Test Real";
        string memory tokenBSymbol = "BRL";

        uint256 supplyToMint = 1000000000 * 1e18; // 1b

        vm.startBroadcast(deployerPrivateKey);

        TestERC20 tokenA = new TestERC20(tokenAName, tokenASymbol, deployerAddress);
        tokenA.mint(deployerAddress, supplyToMint);

        console.log("Token A created at address: ", address(tokenA));

        TestERC20 tokenB = new TestERC20(tokenBName, tokenBSymbol, deployerAddress);
        tokenB.mint(deployerAddress, supplyToMint);

        console.log("Token B created at address: ", address(tokenB));

        vm.stopBroadcast();

        console.log("Balance minted of Token A:", TestERC20(tokenA).balanceOf(deployerAddress));
        console.log("Balance minted of Token B:", TestERC20(tokenB).balanceOf(deployerAddress));
    }
}