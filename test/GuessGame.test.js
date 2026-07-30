const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GuessGame", function () {
  let game, owner, player;
  const entryFee = ethers.parseEther("0.0005");

  beforeEach(async function () {
    [owner, player] = await ethers.getSigners();
    const GuessGame = await ethers.getContractFactory("GuessGame");
    game = await GuessGame.deploy(owner.address);
    await game.waitForDeployment();

    // Fund the pool so a win can be paid out.
    await owner.sendTransaction({
      to: await game.getAddress(),
      value: ethers.parseEther("0.01"),
    });
  });

  it("rejects an incorrect entry fee", async function () {
    await expect(
      game.connect(player).play(5, { value: ethers.parseEther("0.0001") })
    ).to.be.revertedWith("Incorrect entry fee");
  });

  it("rejects a guess out of range", async function () {
    await expect(
      game.connect(player).play(999, { value: entryFee })
    ).to.be.revertedWith("Guess out of range");
  });

  it("emits a GuessResult event on a valid play", async function () {
    await expect(game.connect(player).play(3, { value: entryFee })).to.emit(
      game,
      "GuessResult"
    );
  });

  it("lets the owner update game parameters", async function () {
    await game.connect(owner).setParams(
      ethers.parseEther("0.001"),
      20,
      5
    );
    expect(await game.entryFee()).to.equal(ethers.parseEther("0.001"));
    expect(await game.range()).to.equal(20);
    expect(await game.payoutMultiplier()).to.equal(5);
  });

  it("prevents non-owners from withdrawing", async function () {
    await expect(
      game.connect(player).withdrawExcess(ethers.parseEther("0.001"))
    ).to.be.revertedWithCustomError(game, "OwnableUnauthorizedAccount");
  });
});
