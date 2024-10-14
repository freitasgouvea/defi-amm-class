// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/AMMPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { TestERC20 } from "../src/TestERC20.sol";

contract AMMPoolTest is Test {
    AMMPool public ammPool; // Instância do contrato AMMPool
    TestERC20 public tokenA; // Instância do token A (um token ERC20 de teste)
    TestERC20 public tokenB; // Instância do token B (outro token ERC20 de teste)

    address owner = address(0x1); // Endereço do "dono" que vai criar os tokens
    address user1 = address(0x2); // Endereço do usuário 1
    address user2 = address(0x3); // Endereço do usuário 2

    // Variáveis para valores reutilizáveis nos testes
    uint256 public initialLiquidityA = 100000 ether; // Liquidez inicial do token A
    uint256 public initialLiquidityB = 500000 ether; // Liquidez inicial do token B
    uint256 public swapAmountA = 100 ether;          // Quantidade de token A a ser trocado
    uint256 public swapAmountB = 500 ether;          // Quantidade de token B a ser trocado
    uint256 public minSwapAmountAtoB = 480 ether;    // Valor mínimo aceitável ao trocar 100 ether A por B
    uint256 public minSwapAmountBtoA = 95 ether;     // Valor mínimo aceitável ao trocar 500 ether B por A

    function setUp() public {
        vm.startPrank(owner); // Simula o owner fazendo todas as transações
        tokenA = new TestERC20("Token A", "TKA", owner); // Cria o token A
        tokenB = new TestERC20("Token B", "TKB", owner); // Cria o token B

        ammPool = new AMMPool(address(tokenA), address(tokenB)); // Cria o pool AMM com os dois tokens

        // O dono cria tokens e distribui para os usuários para testes
        tokenA.mint(user1, 1000000 ether);
        tokenB.mint(user1, 1000000 ether);
        tokenA.mint(user2, 1000000 ether);
        tokenB.mint(user2, 1000000 ether);
        vm.stopPrank();

        // Aprova o contrato AMMPool para gastar os tokens dos usuários
        vm.startPrank(user1);
        tokenA.approve(address(ammPool), 1000000 ether);
        tokenB.approve(address(ammPool), 1000000 ether);
        vm.stopPrank();
        
        vm.startPrank(user2);
        tokenA.approve(address(ammPool), 1000000 ether);
        tokenB.approve(address(ammPool), 1000000 ether);
        vm.stopPrank();
    }

    function testAddLiquidity() public {
        vm.startPrank(user1); // Usuário 1 faz a transação
        uint256 liquidity = ammPool.addLiquidity(initialLiquidityA, initialLiquidityB); // Adiciona liquidez
        vm.stopPrank();

        // Verifica se os valores estão corretos
        assertEq(ammPool.balanceOf(user1), liquidity); // Verifica se a quantidade de LP tokens emitida está correta
        assertEq(ammPool.totalSupply(), liquidity);    // Verifica se o total de liquidez no pool está correto
        assertEq(ammPool.reserveA(), initialLiquidityA); // Verifica a reserva de token A no pool
        assertEq(ammPool.reserveB(), initialLiquidityB); // Verifica a reserva de token B no pool
    }

    function testRemoveLiquidity() public {
        vm.startPrank(user1);
        uint256 liquidity = ammPool.addLiquidity(initialLiquidityA, initialLiquidityB); // Adiciona liquidez

        // Remove liquidez
        (uint256 amountA, uint256 amountB) = ammPool.removeLiquidity(liquidity);
        vm.stopPrank();

        // Verifica se os valores removidos estão corretos
        assertEq(amountA, initialLiquidityA);
        assertEq(amountB, initialLiquidityB);
        assertEq(tokenA.balanceOf(user1), 1000000 ether); // Verifica o saldo final do usuário 1 após remover liquidez
        assertEq(tokenB.balanceOf(user1), 1000000 ether); 
    }

    function testSwapTokenAForTokenB() public {
        uint256 balanceBefore = tokenB.balanceOf(user2); // Salva o saldo de token B do usuário 2 antes do swap

        // Adiciona liquidez primeiro
        vm.startPrank(user1);
        ammPool.addLiquidity(initialLiquidityA, initialLiquidityB);
        vm.stopPrank();

        // Realiza a troca de token A por token B
        vm.startPrank(user2);
        uint256 amountOut = ammPool.swap(swapAmountA, address(tokenA), minSwapAmountAtoB); // Usuário 2 troca token A por B
        vm.stopPrank();

        // Verifica se o swap foi bem-sucedido e o saldo foi atualizado corretamente
        assertGt(amountOut, minSwapAmountAtoB); // Verifica se a quantidade recebida foi maior que o mínimo esperado
        assertEq(tokenB.balanceOf(user2), balanceBefore + amountOut); // Verifica o novo saldo de token B do usuário 2
        assertEq(ammPool.reserveA(), initialLiquidityA + swapAmountA); // Verifica a nova reserva de token A no pool
        assertEq(ammPool.reserveB(), initialLiquidityB - amountOut); // Verifica a nova reserva de token B no pool
    }

    function testSwapTokenBForTokenA() public {
        uint256 balanceBefore = tokenA.balanceOf(user2); // Salva o saldo de token A do usuário 2 antes do swap

        // Adiciona liquidez primeiro
        vm.startPrank(user1);
        ammPool.addLiquidity(initialLiquidityA, initialLiquidityB);
        vm.stopPrank();

        // Realiza a troca de token B por token A
        vm.startPrank(user2);
        uint256 amountOut = ammPool.swap(swapAmountB, address(tokenB), minSwapAmountBtoA); // Usuário 2 troca token B por A
        vm.stopPrank();

        // Verifica se o swap foi bem-sucedido e o saldo foi atualizado corretamente
        assertGt(amountOut, minSwapAmountBtoA); // Verifica se a quantidade recebida foi maior que o mínimo esperado
        assertEq(tokenA.balanceOf(user2), balanceBefore + amountOut); // Verifica o novo saldo de token A do usuário 2
        assertEq(ammPool.reserveB(), initialLiquidityB + swapAmountB); // Verifica a nova reserva de token B no pool
        assertEq(ammPool.reserveA(), initialLiquidityA - amountOut); // Verifica a nova reserva de token A no pool
    }

    function testCalculatePrice() public {
        // Adiciona liquidez primeiro
        vm.startPrank(user1);
        ammPool.addLiquidity(initialLiquidityA, initialLiquidityB);
        vm.stopPrank();

        // Calcula o preço de token A
        uint256 amountOutAtoB = ammPool.calculatePrice(swapAmountA, address(tokenA));
        assertGt(amountOutAtoB, minSwapAmountAtoB); // Verifica se o valor de saída é maior que o mínimo esperado

        // Calcula o preço de token B
        uint256 amountOutBtoA = ammPool.calculatePrice(swapAmountB, address(tokenB));
        assertGt(amountOutBtoA, minSwapAmountBtoA); // Verifica se o valor de saída é maior que o mínimo esperado
    }
}
