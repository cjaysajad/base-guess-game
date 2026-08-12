const hre = require("hardhat");
async function main() {
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const GuessGame = await hre.ethers.getContractFactory("GuessGame");
  const game = await GuessGame.deploy(deployer.address);
  await game.waitForDeployment();

  const address = await game.getAddress();
  console.log("GuessGame deployed to:", address);

  // Fund the prize pool a bit so the first winners can be paid.
  const fundTx = await deployer.sendTransaction({
    to: address,
    value: hre.ethers.parseEther("0.01"),
  });
  await fundTx.wait();
  console.log("Funded initial prize pool with 0.01 ETH");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
