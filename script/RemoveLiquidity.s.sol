// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0;

import { Script } from "../lib/forge-std/src/Script.sol";
import { console } from "../lib/forge-std/src/console.sol";
import { AMMPool } from '../src/AMMPool.sol';
import { TestERC20 } from '../src/TestERC20.sol';

contract RemoveLiquidity is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PV_KEY");  
        address deployerAddress = vm.envAddress("DEPLOYER_ADDRESS"); 
      
        // Configurations
        address poolAddress = vm.envAddress("POOL_ADDRESS");    // Deployed pool address
        address tokenA = vm.envAddress("TOKEN_A_ADDRESS");      // Address of Token A
        address tokenB = vm.envAddress("TOKEN_B_ADDRESS");      // Address of Token B
        uint256 liquidityToRemove = 2236067977499789696409173;  // Amount of LP Token to remove

        // Check balances
        console.log("Balances before:");
        console.log("Balance of Token A:", TestERC20(tokenA).balanceOf(deployerAddress));
        console.log("Balance of Token B:", TestERC20(tokenB).balanceOf(deployerAddress));
        console.log("Balance of Token LP:", AMMPool(poolAddress).balanceOf(deployerAddress));

        vm.startBroadcast(deployerPrivateKey);

        // Instantiate the Router and Factory contracts
        AMMPool pool = AMMPool(poolAddress);

        // Remove liquidity to the token pair
        (uint256 amountA, uint256 amountB) = pool.removeLiquidity(
          liquidityToRemove
        );

        vm.stopBroadcast();

        console.log("Remove liquidity with success!");
        console.log("Amount of Token A recieved:", amountA);
        console.log("Amount of Token B recieved:", amountB);

        console.log("Balances after:");
        console.log("Balance of Token A:", TestERC20(tokenA).balanceOf(deployerAddress));
        console.log("Balance of Token B:", TestERC20(tokenB).balanceOf(deployerAddress));
        console.log("Balance of Token LP:", AMMPool(poolAddress).balanceOf(deployerAddress));
    }
}