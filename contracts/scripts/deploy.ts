import { ethers } from "hardhat";

async function main() {
  const icebearTokenAddress = "0x4476D018744ef3b24a5446Df4c13b5FE2703C2B4";

  const AMM = await ethers.getContractFactory("AMM");
  const amm = await AMM.deploy(icebearTokenAddress);

  await amm.deployed();

  console.log(
    `AMM contract deployed to ${amm.address}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});

/*
npx hardhat run scripts/deploy.ts --network alfajores
0x60f61116F2196E0130F4A79DBd7282090dFdE47F
*/