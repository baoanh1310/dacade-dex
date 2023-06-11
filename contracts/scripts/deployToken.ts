import { ethers } from "hardhat";

async function main() {
  const IcebearToken = await ethers.getContractFactory("IcebearToken");
  const token = await IcebearToken.deploy();

  await token.deployed();

  console.log(
    `IcebearToken contract deployed to ${token.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/*
npx hardhat run scripts/deployToken.ts --network alfajores
*/