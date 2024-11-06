const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("TreasureHunt Contract", function () {
    let TreasureHunt;
    let treasureHunt;
    let owner;
    let player1;
    let player2;

    const PARTICIPATION_FEE = ethers.parseUnits("20000", "gwei"); // 20000 gwei
    const MOVE_FEE = ethers.parseUnits("10000", "gwei"); // 10000 gwei

    const LESS_PARTICIPATION_FEE = ethers.parseUnits("19999", "gwei"); // 1 less than required gwei
    const LESS_MOVE_FEE = ethers.parseUnits("9999", "gwei"); // 1 less than required gwei

    async function loadFixtures() {
        // Get signers
        [owner, player1, player2] = await ethers.getSigners();
        
        // Deploy the contract
        const TreasureHuntFactory = await ethers.getContractFactory("TreasureHunt");
        treasureHunt = await TreasureHuntFactory.deploy();
        await treasureHunt.waitForDeployment();

        return { treasureHunt, owner, player1, player2 };
    }

    describe("Participation", function () {
        it("Should allow a player to participate in the game", async function () {
            const { treasureHunt, player1 } = await loadFixtures();

            // Player 1 participates
            await treasureHunt.connect(player1).participate({ value: PARTICIPATION_FEE });
            await expect(treasureHunt.connect(player1).participate({ value: LESS_PARTICIPATION_FEE })).to.be.revertedWith("Participation fee: < 20000 gwei");

            expect(await treasureHunt.playerPositions(player1.address)).to.equal(0);
            expect(await treasureHunt.getCurrentTurn()).to.equal(player1.address);
        });

        it("Should not allow a player to participate more than once", async function () {
            const { treasureHunt, player1 } = await loadFixtures();

            await treasureHunt.connect(player1).participate({ value: PARTICIPATION_FEE });
            await expect(
                treasureHunt.connect(player1).participate({ value: PARTICIPATION_FEE })
            ).to.be.revertedWith("Already participating");
        });
    });

    describe("Movement", function () {
        beforeEach(async function () {
            const { treasureHunt, player1, player2} = await loadFixtures();
            await treasureHunt.connect(player1).participate({ value: PARTICIPATION_FEE });
        });

        it("Should allow the current player to move right", async function () {
            // const currentPlayerTurn = await treasureHunt.getCurrentTurn();
            // console.log(currentPlayerTurn);
            // console.log(player1.address);
            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE });
            expect(await treasureHunt.playerPositions(player1.address)).to.equal(1); // Ensure initial position remains valid
        });

        it("Should not allow out-of-bounds moves", async function () {
            const GRID_SIZE = await treasureHunt.GRID_SIZE();
            // console.log(GRID_SIZE);
            await expect(treasureHunt.connect(player1).moveUp({ value: MOVE_FEE })).to.be.revertedWith("move up out of bounds");
            await expect(treasureHunt.connect(player1).moveLeft({ value: MOVE_FEE })).to.be.revertedWith("move left out of bounds");
            await expect(treasureHunt.connect(player1).moveRight({ value: LESS_MOVE_FEE })).to.be.revertedWith("move fee: < 10000 gwei");

            await treasureHunt.connect(player1).moveDown({ value: MOVE_FEE }) ;

            expect(await treasureHunt.playerPositions(player1.address)).to.equal(GRID_SIZE); // Ensure moveDown positions GRID_SIZE
        });

        it("Should alternate turns between players", async function () {
            // should not win in between
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);

            await treasureHunt.connect(player2).participate({ value: PARTICIPATION_FEE });
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);

            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE }); //1
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);
            expect(await treasureHunt.getCurrentTurn()).to.equal(player2.address); // Turn should now be Player 2's

            await expect(treasureHunt.connect(player1).moveRight({ value: MOVE_FEE })).to.be.revertedWith("not your turn");
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);

            await treasureHunt.connect(player2).moveDown({ value: MOVE_FEE });
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);
            expect(await treasureHunt.getCurrentTurn()).to.equal(player1.address);

            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE }); //2
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);
            expect(await treasureHunt.getCurrentTurn()).to.equal(player2.address); // Turn should now be Player 2's

            await treasureHunt.connect(player2).moveDown({ value: MOVE_FEE });
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);
            await expect(treasureHunt.connect(player1).moveRight({ value: MOVE_FEE })).to.be.revertedWith("move right out of bounds");

            await treasureHunt.connect(player1).moveDown({ value: MOVE_FEE });
            await treasureHunt.connect(owner).updateTreasurePositionExternal(8);
            await expect(treasureHunt.connect(player2).moveDown({ value: MOVE_FEE })).to.be.revertedWith("move down out of bounds");

        });

        it.skip("Should allow a player to win the game with the correct reward", async function () {
            await treasureHunt.connect(owner).updateTreasurePositionExternal(2);

            // Record initial balances
            const contractBalanceBefore = await ethers.provider.getBalance(treasureHunt.target) + (MOVE_FEE)*BigInt(2);
            const playerBalanceBefore = await ethers.provider.getBalance(player1.address) - (MOVE_FEE)*BigInt(2);

            // Move player1 to reach treasure and win
            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE });
            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE });

            // Calculate expected reward (90% of the contract balance)
            const expectedReward = (contractBalanceBefore*(BigInt(90)))/(BigInt(100));

            // Get final balances after the win
            const contractBalanceAfter = await ethers.provider.getBalance(treasureHunt.target);
            const playerBalanceAfter = await ethers.provider.getBalance(player1.address);

            // Check if player's balance increased by the reward and contract balance decreased by the reward
            expect(playerBalanceAfter).to.equal(playerBalanceBefore+ expectedReward );
            // expect(contractBalanceAfter).to.equal(contractBalanceBefore- expectedReward);

            console.log("Player received the correct reward, and contract balance is updated correctly");
        });        
    });

    describe("Withdraw", function () {
        beforeEach(async function () {
            const { treasureHunt, player1, player2} = await loadFixtures();
            await treasureHunt.connect(player1).participate({ value: PARTICIPATION_FEE });
            await treasureHunt.connect(owner).updateTreasurePositionExternal(2);

            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE });
            await treasureHunt.connect(player1).moveRight({ value: MOVE_FEE });

            // player1 wins here
        });

        it("Should allow the owner to withdraw funds", async function () {
            await treasureHunt.connect(owner).withdraw();
            expect(await ethers.provider.getBalance(treasureHunt.target)).to.equal(0);
        });

        it("Should not allow non-owners to withdraw", async function () {
            const OWNER_ROLE = await treasureHunt.connect(owner).getOWNER_ROLE() ;
            await expect(treasureHunt.connect(player1).withdraw())
                .to.be.revertedWithCustomError(
                    treasureHunt,
                    "AccessControlUnauthorizedAccount"
              ).withArgs(player1.address, OWNER_ROLE);;
        });
    });
});

