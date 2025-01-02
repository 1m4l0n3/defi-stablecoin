# Decentralized Stablecoin Project

## 1. Overview

This project implements a decentralized stablecoin system using Ethereum-based smart contracts. The stablecoin is pegged to the USD and collateralized by assets like ETH and BTC. The system includes a minting mechanism that is algorithmic, and the stablecoin is governed by the `DSCEngine`.

## 2. Key Features

- **ERC20 Standard**: The `DecentralizedStableCoin` contract is based on the ERC20 standard, providing basic functionality for token transfers and balances.
- **Burnable Token**: The token supports burning functionality, allowing the owner to reduce the total supply.
- **Minting**: The owner can mint new tokens to a specified address.
- **Governance**: The contract is governed by the `Ownable` contract, ensuring only the owner can mint or burn tokens.

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
