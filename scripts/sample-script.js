// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require('hardhat');

async function main() {
  // // Hardhat always runs the compile task when running scripts with its command
  // // line interface.
  // //
  // // If this script is run directly using `node` you may want to call compile
  // // manually to make sure everything is compiled
  // // await hre.run('compile');

  // // We get the contract to deploy
  // const Greeter = await hre.ethers.getContractFactory("Greeter");
  // const greeter = await Greeter.deploy("Hello, Hardhat!");

  // await greeter.deployed();

  // console.log("Greeter deployed to:", greeter.address);

  const poolVote = await hre.ethers.getContractAt('IClsPoolVote', '0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9');

  await poolVote.getReceipt('5', '0x052734DCcaE11dd0C3dF61Ab2b5FDa8FC8207E63').then(console.log);
  // await poolVote.latestRoundId().then(console.log);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
