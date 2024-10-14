// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AMMPool is ReentrancyGuard {
    IERC20 public tokenA;  // Primeiro token do par
    IERC20 public tokenB;  // Segundo token do par

    uint256 public reserveA;  // Reservas do tokenA no pool
    uint256 public reserveB;  // Reservas do tokenB no pool
    
    uint256 public totalSupply;  // Total de tokens de liquidez (LP tokens) emitidos
    
    mapping(address => uint256) public balanceOf;  // Armazena o saldo de tokens LP de cada usuário

    // Eventos para registrar as operações de mint, burn e swap
    event Mint(address indexed sender, uint256 amountA, uint256 amountB);
    event Burn(address indexed sender, uint256 amountA, uint256 amountB);
    event Swap(address indexed sender, uint256 amountIn, uint256 amountOut, address tokenIn);

    // Construtor que inicializa o par de tokens no pool
    constructor(address _tokenA, address _tokenB) {
        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
    }

    // Função para adicionar liquidez ao pool
    // É necessária a aprovação deste contrato gastar ambos os tokens antes de executar a função
    function addLiquidity(uint256 amountA, uint256 amountB) external nonReentrant returns (uint256 liquidity) {
        // Transferindo os tokens do usuário para o contrato
        tokenA.transferFrom(msg.sender, address(this), amountA);
        tokenB.transferFrom(msg.sender, address(this), amountB);

        if (totalSupply == 0) {
            // Primeira adição de liquidez define as reservas iniciais com base na raiz quadrada do produto das quantidades fornecidas
            liquidity = sqrt(amountA * amountB);
        } else {
            // Cálculo de liquidez baseado nas proporções das reservas atuais
            liquidity = min(
                (amountA * totalSupply) / reserveA,
                (amountB * totalSupply) / reserveB
            );
        }

        // Verifica se a quantidade de liquidez calculada é válida
        require(liquidity > 0, "Insufficient liquidity");

        // Atualiza o saldo de tokens LP do usuário e o totalSupply
        balanceOf[msg.sender] += liquidity;
        totalSupply += liquidity;

        // Atualiza as reservas do pool
        reserveA += amountA;
        reserveB += amountB;

        emit Mint(msg.sender, amountA, amountB);  // Emite o evento de minting
    }

    // Função para remover liquidez do pool
    function removeLiquidity(uint256 liquidity) external nonReentrant returns (uint256 amountA, uint256 amountB) {
        // Verifica se o usuário possui tokens LP suficientes
        require(balanceOf[msg.sender] >= liquidity, "Insufficient LP tokens");

        // Calcula os montantes de tokenA e tokenB com base na proporção de tokens LP queimados
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;

        // Atualiza o saldo de tokens LP do usuário e o totalSupply
        balanceOf[msg.sender] -= liquidity;
        totalSupply -= liquidity;

        // Atualiza as reservas do pool
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfere os tokens de volta para o usuário
        tokenA.transfer(msg.sender, amountA);
        tokenB.transfer(msg.sender, amountB);

        emit Burn(msg.sender, amountA, amountB);  // Emite o evento de burning
    }

    // Função para realizar a troca (swap) entre os tokens
    // É necessária a aprovação deste contrato gastar o tokenIn antes de executar a função
    function swap(uint256 amountIn, address tokenIn, uint256 minAmountOut) external nonReentrant returns (uint256 amountOut) {
        // Verifica se o token de entrada é válido (tokenA ou tokenB)
        require(tokenIn == address(tokenA) || tokenIn == address(tokenB), "Invalid token");

        // Define qual token está sendo enviado e qual será recebido
        bool isTokenAIn = tokenIn == address(tokenA);
        IERC20 inputToken = isTokenAIn ? tokenA : tokenB;
        IERC20 outputToken = isTokenAIn ? tokenB : tokenA;
        uint256 inputReserve = isTokenAIn ? reserveA : reserveB;
        uint256 outputReserve = isTokenAIn ? reserveB : reserveA;

        // Transfere o token de entrada para o contrato
        inputToken.transferFrom(msg.sender, address(this), amountIn);

        // Aplica a fórmula do produto constante (x * y = k) com uma taxa de 0.3%
        uint256 amountInWithFee = (amountIn * 997) / 1000;  // Taxa de 0.3% aplicada
        amountOut = (amountInWithFee * outputReserve) / (inputReserve + amountInWithFee);

        // Garante que a quantidade de saída seja válida e protege contra slippage/frontrunning
        require(amountOut >= minAmountOut, "Slippage exceeded");

        // Transfere o token de saída para o usuário
        outputToken.transfer(msg.sender, amountOut);

        // Atualiza as reservas dependendo do token que foi trocado
        if (isTokenAIn) {
            reserveA += amountIn;
            reserveB -= amountOut;
        } else {
            reserveB += amountIn;
            reserveA -= amountOut;
        }

        // Verifica se a constante do produto não foi violada para prevenir ataques de flash loan
        require(reserveA * reserveB >= inputReserve * outputReserve, "Invariant violation");

        emit Swap(msg.sender, amountIn, amountOut, tokenIn);  // Emite o evento de swap
    }

    // Função que calcula quantos tokens de saída o usuário receberá baseado em um token de entrada e uma quantidade específica
    function calculatePrice(uint256 amountIn, address tokenIn) public view returns (uint256 amountOut) {
        require(reserveA > 0 && reserveB > 0, "Insufficient liquidity");

        uint256 amountInWithFee = amountIn * 997 / 1000;  // Aplica a taxa de 0.3%
        
        // Verifica qual token é o de entrada e calcula o token de saída
        if (tokenIn == address(tokenA)) {
            // Se o token de entrada for tokenA, calculamos a quantidade de tokenB que será recebida
            amountOut = (amountInWithFee * reserveB) / (reserveA + amountInWithFee);
        } else if (tokenIn == address(tokenB)) {
            // Se o token de entrada for tokenB, calculamos a quantidade de tokenA que será recebida
            amountOut = (amountInWithFee * reserveA) / (reserveB + amountInWithFee);
        } else {
            // Caso o token de entrada não seja válido, lançamos um erro
            revert("Invalid tokenIn address");
        }
    }

    // Função auxiliar para retornar o menor valor entre dois números
    function min(uint256 x, uint256 y) private pure returns (uint256) {
        return x < y ? x : y;
    }

    // Função auxiliar para calcular a raiz quadrada de um número (usada no cálculo inicial de liquidez)
    function sqrt(uint256 x) private pure returns (uint256) {
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return z;
    }
}
