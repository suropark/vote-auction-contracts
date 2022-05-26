// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require('hardhat');

async function main() {
  //0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9

  const rewardController = await ethers.getContractAt('IClsPoolVote', '0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9');

  await rewardController.name().then(console.log);
  await rewardController.latestRoundId().then(console.log);
  await rewardController.roundCount().then(console.log);
  await rewardController.getTotalClsAvailable(4).then(console.log);
  await rewardController.getEndTime(4).then(console.log);
  await rewardController.getVotablePoolIds(4).then(console.log);
  await rewardController.getReceipt(4, '0x052734DCcaE11dd0C3dF61Ab2b5FDa8FC8207E63').then(console.log);
  await rewardController.getClsAvailable(4, '0x052734DCcaE11dd0C3dF61Ab2b5FDa8FC8207E63').then(console.log);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
