import { Contract } from "ethers";
import {
  TOKEN_CONTRACT_ABI,
  TOKEN_CONTRACT_ADDRESS,
} from "../constants";

export const faucet = async (
  signer
) => {
  try {
    const tokenContract = new Contract(
      TOKEN_CONTRACT_ADDRESS,
      TOKEN_CONTRACT_ABI,
      signer
    );
    let tx = await tokenContract.faucet();
    await tx.wait();
  } catch (err) {
    console.error(err);
  }
};
