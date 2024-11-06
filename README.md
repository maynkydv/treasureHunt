# treasureHunt
**Treasure Hunt Game** smart contract project:

# Treasure Hunt Game

A Solidity-based, grid-based treasure hunting game where players navigate a 10x10 grid to locate a hidden treasure. Players can join the game, pay a fee to move in various directions, and win rewards if they find the treasure.

## Table of Contents
- [Overview](#overview)
- [Installation](#installation)
- [Usage](#usage)
- [Commands](#commands)
- [License](#license)

## Overview
This game enables players to move on a 10x10 grid to search for a hidden treasure. Players must pay a fee to join and an additional fee for each move. The treasure location updates based on player moves, providing a dynamic and challenging game experience. Players receive rewards in Ether if they find the treasure.

### Key Features
- Players can join the game by paying a participation fee.
- Game mechanics allow movement in four directions (up, down, left, right) with additional movement fees.
- The treasure's position updates based on players' moves.
- Winning players are rewarded, and the game resets after a win.
- Admin can withdraw the contract balance.
- Supports roles using `AccessControl` from OpenZeppelin.

## Installation
### Prerequisites
- **Node.js** and **npm** are required. You can download them [here](https://nodejs.org/).
- **Hardhat** for contract testing and deployment.

### Steps
1. Clone the repository:
    ```bash
    git clone https://github.com/maynkydv/treasureHunt
    cd TreasureHunt_assignment
    ```

2. Install dependencies:
    ```bash
    npm install
    ```

3. Compile the smart contracts:
    ```bash
    npx hardhat compile
    ```

## Usage

### 1. Run Tests
Test the contract using Hardhat:
```bash
npx hardhat test
```

### 2. Deploy to Local Network
You can deploy the contract to a local Hardhat network:
```bash
npx hardhat run scripts/deploy.js --network localhost
npx hardhat run scripts/deploy.js --network sepolia
```

### 3. Console Logging
The game leverages Hardhat's `console.log` feature for debugging. Make sure to run a local Hardhat network to see the logs.

### Important Functions
- **participate()**: Allows a player to join the game by paying a participation fee.
- **moveUp(), moveDown(), moveLeft(), moveRight()**: Moves the player in the respective direction with a movement fee.
- **getCurrentTurn()**: Returns the address of the player whose turn it is.
- **withdraw()**: Allows the owner to withdraw the balance from the contract.

## Commands

### Installing Dependencies
```bash
npm install
```

### Git Commands
Initialize a git repository, add, and commit changes:
```bash
git init
git add .
git commit -m "Initial commit"
```

Push changes to your repository:
```bash
git remote add origin https://github.com/maynkydv/treasureHunt
git push -u origin main
```

### License
This project is licensed under the [UNLICENSED](LICENSE) license.

---

**Note**: Ensure that you test the contract in a development environment like the Hardhat local network before deploying it to a testnet or mainnet.
```

This README provides clear instructions on setting up, testing, deploying, and playing the game, along with important commands and usage notes. Let me know if you'd like further customization!