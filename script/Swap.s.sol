// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { Script } from "../lib/forge-std/src/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { AMMPool } from '../src/AMMPool.sol';
import { TestERC20 } from '../src/TestERC20.sol';

contract Swap is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PV_KEY");  
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS"); 
      
        // Configurations
        address poolAddress = vm.envAddress("POOL_ADDRESS");    // Deployed pool address
        address tokenIn = vm.envAddress("TOKEN_A_ADDRESS");     // Address of Token A
        address tokenOut = vm.envAddress("TOKEN_B_ADDRESS");    // Address of Token B
        uint256 amountIn = 10000 * 1e18;                        // Amount in token A
        uint256 minAmountOut = amountIn * 950 / 1000;           // Min amount out of Token B (5% slippage)

        // Check balances
        console.log("Balances before:");
        console.log("Balance of Token A (In):", TestERC20(tokenIn).balanceOf(deployerAddress));
        console.log("Balance of Token B (Out):", TestERC20(tokenOut).balanceOf(deployerAddress));

        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the Router and Factory contracts
        AMMPool pool = AMMPool(poolAddress);

        // Approve tokens for the router to spend
        TestERC20(tokenIn).approve(poolAddress, amountIn);

        // Check allowances
        console.log("Allowances:");
        console.log("Allowance of Token A (In):", TestERC20(tokenIn).allowance(deployerAddress, poolAddress));

        // Add liquidity to the token pair
        uint256 amountOut = pool.swap(
            amountIn,
            tokenIn,
            minAmountOut
        );

        vm.stopBroadcast();

        console.log("Swap with success!");
        console.log("Amount of Token A In:", amountIn);
        console.log("Amount of Token B Out:", amountOut);

        console.log("Balances after:");
        console.log("Balance of Token A:", TestERC20(tokenIn).balanceOf(deployerAddress));
        console.log("Balance of Token B:", TestERC20(tokenOut).balanceOf(deployerAddress));
    }
}
