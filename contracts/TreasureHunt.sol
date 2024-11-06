// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/access/AccessControl.sol";

// Uncomment this line to use console.log
import "hardhat/console.sol";

contract TreasureHunt is AccessControl{

    // Role for deployer permission
    bytes32 constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 constant PARTICIPANT_ROLE = keccak256("PARTICIPANT_ROLE");


    uint8 public constant GRID_SIZE = 3; // 10x10 grid //! Chnage to 10 after testing
    uint8 public treasurePosition; // Position of the treasure on the grid //!should be private after testing
    address public owner; 

    // Store each player's current position on the grid
    mapping(address => uint8) public playerPositions;
    address[] public players; // Track active players
    uint256 public currentTurnIndex = 0; // Track the current player's turn index

    constructor() payable {
        owner = msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(OWNER_ROLE, msg.sender);
        // Set initial treasure position to a random position within 0-99
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.number))) % (GRID_SIZE * GRID_SIZE));
    }

    // Participate in the game by paying 20000 gwei and setting initial position to 0
    function participate() external payable {
        require(msg.value >= 20000 gwei, "Participation fee: < 20000 gwei");
        require(!hasRole(PARTICIPANT_ROLE, msg.sender), "Already participating");
        _grantRole(PARTICIPANT_ROLE, msg.sender);


        playerPositions[msg.sender] = 0; // Set initial position to 0
        players.push(msg.sender); // Track player
    }

    function getCurrentTurn() public view returns (address) {
        return players[currentTurnIndex];
    }
    
    modifier onlyCurrentTurn() {
        require(msg.sender == players[currentTurnIndex], "not your turn");
        _;
    }

    // ! should be removed after testing
    function updateTreasurePositionExternal(uint8 fixedTreasurePosition) external onlyRole(OWNER_ROLE){
        treasurePosition = fixedTreasurePosition;
    }

    // ! should be removed after testing
    function getOWNER_ROLE() external view onlyRole(OWNER_ROLE) returns (bytes32){
        return OWNER_ROLE ;
    }

    function moveUp() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn{
        require(msg.value >= 10000 gwei, "move fee: < 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition >= GRID_SIZE, "move up out of bounds");

        uint8 newPosition = currentPosition - GRID_SIZE;
        executeMove(newPosition);
    }

    function moveDown() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn{
        require(msg.value >= 10000 gwei, "move fee: < 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition < GRID_SIZE * (GRID_SIZE - 1), "move down out of bounds");

        uint8 newPosition = currentPosition + GRID_SIZE;
        executeMove(newPosition);
    }

    function moveLeft() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn{
        require(msg.value >= 10000 gwei, "move fee: < 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition % GRID_SIZE != 0, "move left out of bounds");

        uint8 newPosition = currentPosition - 1;
        executeMove(newPosition);
    }

    function moveRight() external payable onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn{
        require(msg.value >= 10000 gwei, "move fee: < 10000 gwei");
        uint8 currentPosition = playerPositions[msg.sender];
        require(currentPosition % GRID_SIZE != GRID_SIZE - 1, "move right out of bounds");

        uint8 newPosition = currentPosition + 1;
        executeMove(newPosition);
    }

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

    function updateTreasurePosition(uint8 playerPosition) internal {
        if (playerPosition % 5 == 0) {
            // Move treasure to a random adjacent position if player moves to a multiple of 5
            treasurePosition = getRandomAdjacentPosition(treasurePosition);
        } else if (isPrime(playerPosition)) {
            // Jump treasure to a random position if player moves to a prime position
            treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % (GRID_SIZE * GRID_SIZE));
        }
    }

    function isPrime(uint256 num) internal pure returns (bool) {
        if (num < 2) return false;
        for (uint256 i = 2; i * i <= num; i++) {
            if (num % i == 0) return false;
        }
        return true;
    }

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

    // Reset the game state
    function resetGame() internal onlyRole(PARTICIPANT_ROLE) onlyCurrentTurn {
        for (uint256 i = 0; i < players.length; i++) {
            delete playerPositions[players[i]]; // Clear each player's position
            _revokeRole(PARTICIPANT_ROLE, players[i]);
        }
        currentTurnIndex = 0;

        delete players; // Clear the players array
        treasurePosition = uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % (GRID_SIZE * GRID_SIZE));
    }

    function withdraw() external onlyRole(OWNER_ROLE){
        // require(msg.sender == owner, "only owner can withdraw");
        // require(players.length != 0, "game is in progress");
        uint256 balance = address(this).balance;
        payable(owner).transfer(balance);
    }

    receive() external payable {}
}
