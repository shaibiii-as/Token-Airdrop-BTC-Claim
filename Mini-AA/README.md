# MiniAdoption Amplifier Smart Contracts

## Overview

MiniAA is a reward pools smart contract. free pool and points pool.

`miniAA` is a reward pool smart contract that have a 2 pools(FreePoll ,PointPool). User deposit points into Point Pool and earn PTP reawrd by claiming at the end of day. Same as user enters into Free Pool without depositing any points and claim reward in the form of PTP token at the end of the day.

### 📦 Installation

```console
$ yarn
```

### ⛏️ Compile

```console
$ yarn compile
```

This task will compile all smart contracts in the `contracts` directory.
ABI files will be automatically exported in `build/abi` directory.

### 📚 Documentation

Documentation is auto-generated after each build in `docs` directory.

The generated output is a static website containing smart contract documentation.

### 🌡️ Testing

```console
$ yarn test
```

### 📊 Code coverage

```console
$ yarn coverage
```

The report will be printed in the console and a static website containing full report will be generated in `coverage` directory.

### ✨ Code style

```console
$ yarn prettier
```

### ✨ Setting up env

```console
  1 => rename env.example to .env
  2 => updated .env with you credentials
```

### 🐱‍💻 Deploy your contracts

```console
$ npx hardhat  run --network $YOUR_NETWORK_NAME scripts/deploy.js
```

### 🐱‍💻 Verify & Publish contract source code

```console
$ npx hardhat  verify --network mainnet $CONTRACT_ADDRESS $CONSTRUCTOR_ARGUMENTS
```
