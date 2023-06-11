import { Contract, utils } from "ethers";
import {
  EXCHANGE_CONTRACT_ABI,
  EXCHANGE_CONTRACT_ADDRESS,
  TOKEN_CONTRACT_ABI,
  TOKEN_CONTRACT_ADDRESS,
} from "../constants";

export const addLiquidity = async (
  signer,
  addIcebearAmountWei,
  addCeloAmountWei
) => {
  try {
    const tokenContract = new Contract(
      TOKEN_CONTRACT_ADDRESS,
      TOKEN_CONTRACT_ABI,
      signer
    );
    const exchangeContract = new Contract(
      EXCHANGE_CONTRACT_ADDRESS,
      EXCHANGE_CONTRACT_ABI,
      signer
    );
    let tx = await tokenContract.approve(
      EXCHANGE_CONTRACT_ADDRESS,
      addIcebearAmountWei.toString()
    );
    await tx.wait();
    tx = await exchangeContract.addLiquidity(addIcebearAmountWei, {
      value: addCeloAmountWei,
    });
    await tx.wait();
  } catch (err) {
    console.error(err);
  }
};

export const calculateIcebear = async (
  _addCelo = "0",
  celoBalanceContract,
  icebearTokenReserve
) => {
  const _addCeloAmountWei = utils.parseEther(_addCelo);
  const icebearTokenAmount = _addCeloAmountWei
    .mul(icebearTokenReserve)
    .div(celoBalanceContract);
  return icebearTokenAmount;
};
