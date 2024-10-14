// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { Script } from "../lib/forge-std/src/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { AMMPool } from '../src/AMMPool.sol';
import { TestERC20 } from '../src/TestERC20.sol';

contract AddLiquidity is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PV_KEY");  
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS"); 
      
        // Configurations
        address poolAddress = vm.envAddress("POOL_ADDRESS");    // Deployed pool address
        address tokenA = vm.envAddress("TOKEN_A_ADDRESS");      // Address of Token A
        address tokenB = vm.envAddress("TOKEN_B_ADDRESS");      // Address of Token B
        uint256 amountA = 1000000 * 1e18;                       // Amount of Token A
        uint256 amountB = 5000000 * 1e18;                       // Amount of Token B

        // Check balances
        console.log("Balances before:");
        console.log("Balance of Token A:", TestERC20(tokenA).balanceOf(deployerAddress));
        console.log("Balance of Token B:", TestERC20(tokenB).balanceOf(deployerAddress));
        console.log("Balance of Token LP:", AMMPool(poolAddress).balanceOf(deployerAddress));

        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the Router and Factory contracts
        AMMPool pool = AMMPool(poolAddress);

        // Approve tokens for the router to spend
        TestERC20(tokenA).approve(poolAddress, amountA);
        TestERC20(tokenB).approve(poolAddress, amountB);

        // Check allowances
        console.log("Allowances:");
        console.log("Allowance of Token A:", TestERC20(tokenA).allowance(deployerAddress, poolAddress));
        console.log("Allowance of Token B:", TestERC20(tokenB).allowance(deployerAddress, poolAddress));

        // Add liquidity to the token pair
        uint256 liquidity = pool.addLiquidity(
            amountA,
            amountB
        );

        vm.stopBroadcast();

        console.log("Add liquidity with success!");
        console.log("Amount of Token A added:", amountA);
        console.log("Amount of Token B added:", amountB);
        console.log("LP Tokens received:", liquidity);

        console.log("Balances after:");
        console.log("Balance of Token A:", TestERC20(tokenA).balanceOf(deployerAddress));
        console.log("Balance of Token B:", TestERC20(tokenB).balanceOf(deployerAddress));
        console.log("Balance of Token LP:", AMMPool(poolAddress).balanceOf(deployerAddress));
    }
}
