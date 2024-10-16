# defi-amm-class

Este projeto implementa um contrato inteligente de Automated Market Maker (AMM) inspirado no Uniswap v2 para fins educacionais. 

O contrato permite que os usuários adicionem liquidez a um par de tokens ERC20 e realizem trocas (swaps) entre os tokens usando a fórmula do produto constante (`x * y = k`). 

As funcionalidades incluem adicionar/remover liquidez e realizar cálculos de preço de troca entre os tokens.


## Tarefas

### Instalar o Foundry

Para executar os scripts deste repostõrio (./script) você precisa instalar o Fondry.

[Como Instalar o Foundry](https://book.getfoundry.sh/getting-started/installation)

### Instalar as dependencias do projeto

Após instalar o Foundry e antes de executar os scripts, é necessario fazer o build do projeto:

```shell
forge build
```

### Iniciar uma blockchain de testes no localhost usando o anvil

Antes de executar os scripts, inicie uma blockchain local em sua máquina com o Anvil:

```shell
anvil
```

Salve o endereço de uma das carteiras e a sua respectiva chave privada para adicionar ao arquivo `.env`.

### Definir Variáveis de Ambiente

Crie um arquivo `.env` na raiz do projeto e defina as variáveis de ambiente necessárias:

```md
# CONFIGURAÇÕES DA CARTEIRA
PV_KEY=
DEPLOYER_ADDRESS=

# ENDEREÇOS DOS CONTRATOS DEPLOYADOS
TOKEN_A_ADDRESS=
TOKEN_B_ADDRESS=
POOL_ADDRESS=
```

Antes de rodar os scripts, lembre-se de carregar as variáveis:

```shell
source .env
```

## Scripts de Deploy e Interação

### 1. Deploy dos Tokens de Teste

Este script implanta os tokens `TokenA` e `TokenB` na blockchain de teste:

```shell
forge script script/DeployTokens.s.sol:DeployTokens --rpc-url 127.0.0.1:8545 --broadcast -vvvv
```

### 2. Deploy do AMM Pool

Implanta o contrato da pool de AMM:

```shell
forge script script/DeployPool.s.sol:DeployPool --rpc-url 127.0.0.1:8545 --broadcast -vvvv
```

### 3. Adicionar Liquidez

Adiciona liquidez à pool, fornecendo `TokenA` e `TokenB`:

```shell
forge script script/AddLiquidity.s.sol:AddLiquidity --rpc-url 127.0.0.1:8545 --broadcast -vvvv
```

### 4. Realizar Trocas (Swap)

Executa uma troca entre os tokens da pool:

```shell
forge script script/Swap.s.sol:Swap --rpc-url 127.0.0.1:8545 --broadcast -vvvv
```

### 5. Remover Liquidez

Remove liquidez da pool, devolvendo os tokens ao usuário:

```shell
forge script script/RemoveLiquidity.s.sol:RemoveLiquidity --rpc-url 127.0.0.1:8545 --broadcast -vvvv
```

## Executar os Testes

Para rodar os testes localizados na pasta `test`, use o comando abaixo, que também gera um relatório de consumo de gas:

```shell
forge test --gas-report -vvvv
```

## Estrutura do Contrato

### Principais Funcionalidades

- **Adicionar Liquidez**: Os usuários podem fornecer tokens para o pool e, em troca, receber tokens de liquidez (LP tokens) que representam sua participação no pool.
- **Remover Liquidez**: Os LP tokens podem ser trocados de volta pelos tokens originais, removendo a liquidez do pool.
- **Realizar Trocas (Swap)**: Os usuários podem trocar entre os dois tokens suportados pelo pool, pagando uma taxa de 0,3% para cada transação.
- **Calcular Preço de Troca**: Função que permite calcular o preço de saída de um token com base na quantidade de entrada de outro token.

### 1. **Tokens Suportados**

O contrato suporta dois tokens ERC20, `tokenA` e `tokenB`, definidos no momento da implantação:

```solidity
IERC20 public tokenA;  // Primeiro token do par
IERC20 public tokenB;  // Segundo token do par
```

### 2. **Reservas e Liquidez**

- `reserveA` e `reserveB` representam as reservas de `tokenA` e `tokenB`, respectivamente, dentro do pool.
- `totalSupply` é a quantidade total de tokens de liquidez (LP tokens) emitidos.
- `balanceOf` mantém o saldo de tokens de liquidez (LP tokens) de cada usuário.

### 3. **Adicionar Liquidez**

A função `addLiquidity` permite que os usuários depositem uma certa quantidade de `tokenA` e `tokenB` no pool e recebam tokens LP em troca, que representam a proporção de sua contribuição no pool.

```solidity
function addLiquidity(uint256 amountA, uint256 amountB) external returns (uint256 liquidity);
```

**Como funciona**:
- O usuário deve previamente aprovar a transferência dos tokens para o contrato.
- O contrato calcula a quantidade de liquidez a ser atribuída com base nas reservas atuais e nas quantidades fornecidas.
- Tokens LP são emitidos proporcionalmente à contribuição do usuário no pool.

### 4. **Remover Liquidez**

A função `removeLiquidity` permite que os usuários queimem seus tokens LP e recuperem suas participações de `tokenA` e `tokenB` nas reservas do pool.

```solidity
function removeLiquidity(uint256 liquidity) external returns (uint256 amountA, uint256 amountB);
```

**Como funciona**:
- O usuário especifica a quantidade de tokens LP que deseja queimar.
- O contrato calcula a proporção de `tokenA` e `tokenB` que o usuário receberá com base no seu saldo de LP tokens.

### 5. **Trocas (Swap)**

A função `swap` permite que o usuário troque uma quantidade de `tokenA` por `tokenB` (ou vice-versa) com base nas reservas do pool e na fórmula do produto constante (`x * y = k`), aplicando uma taxa de 0,3%.

```solidity
function swap(uint256 amountIn, address tokenIn, uint256 minAmountOut) external returns (uint256 amountOut);
```

**Como funciona**:
- O usuário especifica o token de entrad, a quantidade que deseja trocar e a quantidade minima dos tokens de saída que espera receber.
- A função calcula a quantidade de tokens de saída com base nas reservas atuais e a taxa de 0,3%.
- Verifica se a quantidade de tokens de sáida é maior ou igual a quantidade mínima desejada.
- O contrato transfere os tokens de saída de volta para o usuário e atualiza as reservas.

### 6. **Calcular Preço de Troca**

A função `calculatePrice` permite calcular o valor de tokens de saída que o usuário receberá ao fornecer uma quantidade de tokens de entrada, sem executar a troca real.

```solidity
function calculatePrice(uint256 amountIn, address tokenIn) public view returns (uint256 amountOut);
```

**Como funciona**:
- O usuário fornece o endereço do token de entrada e a quantidade.
- O contrato calcula a quantidade de tokens de saída que seria recebida com base nas reservas atuais.

### 7. **Eventos**

O contrato emite eventos para registrar as operações realizadas, como a adição e remoção de liquidez e as trocas realizadas.

- `Mint`: Emitido quando o usuário adiciona liquidez ao pool.
- `Burn`: Emitido quando o usuário remove liquidez do pool.
- `Swap`: Emitido quando uma troca de tokens é realizada.

### Funções Auxiliares

- **`min(uint256 x, uint256 y)`:** Retorna o menor valor entre dois números. Utilizada no cálculo de liquidez.
- **`sqrt(uint256 x)`:** Calcula a raiz quadrada de um número. Utilizada na primeira adição de liquidez para definir as proporções corretas.

## Materiais de Referência

- [Solidity](https://soliditylang.org/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Uniswap v2 docs](https://docs.uniswap.org/contracts/v2/overview)
- [Uniswap V2 contracts](https://docs.uniswap.org/contracts/v2/concepts/protocol-overview/smart-contracts)
