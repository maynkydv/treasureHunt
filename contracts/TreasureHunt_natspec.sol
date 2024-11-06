// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

/**
 * @title Treasure Hunt Game
 * @dev A grid-based treasure hunting game where players move around a grid to find a hidden treasure.
 * Players can move in four directions and will receive rewards for finding the treasure.
 */
contract TreasureHunt_natspec is AccessControl {

    /// @notice Role for deployer permission
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");

    uint8 public constant GRID_SIZE = 10; 
    uint8 private treasurePosition; 
    address private owner;

    // Store each player's current position on the grid
    mapping(address => uint8) public playerPositions;

    address[] public players;  // Track active players
    uint256 public currentTurnIndex = 0; // Track the current player's turn index

    /**
     * @dev Constructor that initializes the contract and sets the initial treasure position.
     * Sets the deployer as the owner and grants the DEFAULT_ADMIN_ROLE, OWNER_ROLE roles.
     */
    constructor() payable {
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.number))) % (GRID_SIZE * GRID_SIZE));
    }

    /**
     * @notice Participate in the game by paying a fee and setting the initial position.
     * @dev Only players who are not already participating can join.
     * @dev Players must pay at least 20000 gwei to participate.
     */
    function participate() external payable {
        require(msg.value >= 20000 gwei, "Participation fee: 20000 gwei");
        require(playerPositions[msg.sender] == 0, "Already participating");
        _grantRole(PARTICIPANT_ROLE, msg.sender);

        playerPositions[msg.sender] = 0; // Set initial position to 0
        players.push(msg.sender); // Track player
    }

    /**
     * @notice Get the address of the current player whose turn it is.
     * @return The address of the current player.
     */
    function getCurrentTurn() public view returns (address) {
        return players[currentTurnIndex];
    }

    modifier onlyCurrentTurn() {
        require(msg.sender == players[currentTurnIndex], "not your turn");
        _;
    }

    /**
     * @notice Move the player up in the grid.
     * @dev Requires a fee of 10000 gwei and must be the player's turn.
     */
    function moveUp() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn {
        require(msg.value >= 10000 gwei, "move fee: 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition >= GRID_SIZE, "move up out of bounds");

        uint8 newPosition = currentPosition - GRID_SIZE;
        executeMove(newPosition);
    }

    /**
     * @notice Move the player down in the grid.
     * @dev Requires a fee of 10000 gwei and must be the player's turn.
     */
    function moveDown() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn {
        require(msg.value >= 10000 gwei, "move fee: 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition < GRID_SIZE * (GRID_SIZE - 1), "move down out of bounds");

        uint8 newPosition = currentPosition + GRID_SIZE;
        executeMove(newPosition);
    }

    /**
     * @notice Move the player left in the grid.
     * @dev Requires a fee of 10000 gwei and must be the player's turn.
     */
    function moveLeft() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn {
        require(msg.value >= 10000 gwei, "move fee: 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition % GRID_SIZE != 0, "move left out of bounds");

        uint8 newPosition = currentPosition - 1;
        executeMove(newPosition);
    }

    /**
     * @notice Move the player right in the grid.
     * @dev Requires a fee of 10000 gwei and must be the player's turn.
     */
    function moveRight() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn {
        require(msg.value >= 10000 gwei, "move fee: 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition % GRID_SIZE != GRID_SIZE - 1, "move right out of bounds");

        uint8 newPosition = currentPosition + 1;
        executeMove(newPosition);
    }

    /**
     * @notice Execute the move for the player and check if they found the treasure.
     * @param newPosition The new position of the player after the move.
     */
    function executeMove(uint8 newPosition) internal {
        playerPositions[msg.sender] = newPosition;

        if (newPosition == treasurePosition) {
            uint256 reward = (address(this).balance * 90) / 100;
            payable(msg.sender).transfer(reward);

            console.log("Game Over! Player with address %s Wons %s Wei ", msg.sender, reward);
            resetGame(); // Reset the game state after a win
        } else {
            currentTurnIndex = (currentTurnIndex + 1) % players.length;
            updateTreasurePosition(newPosition);
        }
    }

    /**
     * @notice Update the position of the treasure based on the player's move.
     * @param playerPosition The current position of the player.
     */
    function updateTreasurePosition(uint8 playerPosition) internal {
        if (playerPosition % 5 == 0) {
            treasurePosition = getRandomAdjacentPosition(treasurePosition);
        } else if (isPrime(playerPosition)) {
            treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % (GRID_SIZE * GRID_SIZE));
        }
    }

    /**
     * @notice Check if a number is prime.
     * @param num The number to check.
     * @return True if the number is prime, false otherwise.
     */
    function isPrime(uint256 num) internal pure returns (bool) {
        if (num < 2) return false;
        for (uint256 i = 2; i * i <= num; i++) {
            if (num % i == 0) return false;
        }
        return true;
    }

    /**
     * @notice Get a random adjacent position on the grid.
     * @param position The current position of the treasure.
     * @return A new position that is adjacent to the current position.
     */
    function getRandomAdjacentPosition(uint8 position) internal view returns (uint8) {
        uint8[4] memory moves = [position - 1, position + 1, position - GRID_SIZE, position + GRID_SIZE];
        uint8 randomIndex = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % 4);
        uint8 newPosition = moves[randomIndex];

        // Ensure the new position is within grid bounds and adjacent
        if (newPosition < (GRID_SIZE * GRID_SIZE)) {
            return newPosition;
        }
        return position; // If out-of-bounds, return current position
    }

    /**
     * @notice Reset the game state after the treasure has been found.
     */
    function resetGame() internal {
        for (uint256 i = 0; i < players.length; i++) {
            delete playerPositions[players[i]]; // Clear each player's position
            _revokeRole(PARTICIPANT_ROLE, players[i]);
        }
        currentTurnIndex = 0;

        delete players; // Clear the players array
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % (GRID_SIZE * GRID_SIZE));
    }

    /**
     * @notice Withdraw the contract balance to the owner's address.
     * @dev Only the owner can withdraw funds from the contract.
     */
    function withdraw() external onlyRole(OWNER_ROLE) {
        require(msg.sender == owner, "only owner can withdraw");
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    /**
     * @notice Receive Ether into the contract.
     */
    receive() external payable {}
}
