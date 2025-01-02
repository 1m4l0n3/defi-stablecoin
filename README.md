# Decentralized Stablecoin Project

## 1. Overview

This project implements a decentralized stablecoin system using Ethereum-based smart contracts. The stablecoin is pegged to the USD and collateralized by assets like ETH and BTC. The system includes a minting mechanism that is algorithmic, and the stablecoin is governed by the `DSCEngine`.

## 2. Key Features

- **ERC20 Standard**: The `DecentralizedStableCoin` contract is based on the ERC20 standard, providing basic functionality for token transfers and balances.
- **Burnable Token**: The token supports burning functionality, allowing the owner to reduce the total supply.
- **Minting**: The owner can mint new tokens to a specified address.
- **Governance**: The contract is governed by the `Ownable` contract, ensuring only the owner can mint or burn tokens.

---


## 3. Contracts and Functions

### DecentralizedStableCoin.sol
- **Minting**: Allows the owner to mint tokens to a specified address, with checks to prevent minting to the zero address or with zero amount.
- **Burning**: Allows the owner to burn tokens from their balance, with checks to ensure a valid amount is burned.
- **Error Handling**: Includes custom errors to handle invalid operations such as burning more than the current balance or minting to a zero address.

### DSCEngine.sol
- This contract governs the overall minting and burning mechanism for the stablecoin, interacting with the collateral and ensuring the stability of the token.
- It manages the collateral and ensures the stablecoin remains pegged to the USD by adjusting the supply based on market conditions.

### OracleLib.sol
- Provides functions to interact with external price oracles to fetch the current value of the collateral (ETH, BTC) and ensure the stablecoin's stability by adjusting the collateralization ratio.

## Key Functions

- **mint(address _to, uint256 _amount)**: Mints a specified amount of stablecoins to a given address.
- **burn(uint256 _amount)**: Burns a specified amount of stablecoins from the owner's balance.
- **getCollateralValue()**: Fetches the current value of the collateral (ETH, BTC) using an oracle.
- **adjustSupply()**: Adjusts the supply of stablecoins based on the collateral value and target price peg.



## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
