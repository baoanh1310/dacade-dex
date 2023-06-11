import { Contract } from "ethers";
import {
  EXCHANGE_CONTRACT_ABI,
  EXCHANGE_CONTRACT_ADDRESS,
  TOKEN_CONTRACT_ABI,
  TOKEN_CONTRACT_ADDRESS,
} from "../constants";

export const getAmountOfTokensReceivedFromSwap = async (
  _swapAmountWei,
  provider,
  celoSelected,
  celoBalance,
  reservedIcebear
) => {
  const exchangeContract = new Contract(
    EXCHANGE_CONTRACT_ADDRESS,
    EXCHANGE_CONTRACT_ABI,
    provider
  );
  let amountOfTokens;
  if (celoSelected) {
    amountOfTokens = await exchangeContract.getAmountOfTokens(
      _swapAmountWei,
      celoBalance,
      reservedIcebear
    );
  } else {
    amountOfTokens = await exchangeContract.getAmountOfTokens(
      _swapAmountWei,
      reservedIcebear,
      celoBalance
    );
  }

  return amountOfTokens;
};

export const swapTokens = async (
  signer,
  swapAmountWei,
  tokenToBeReceivedAfterSwap,
  celoSelected
) => {
  const exchangeContract = new Contract(
    EXCHANGE_CONTRACT_ADDRESS,
    EXCHANGE_CONTRACT_ABI,
    signer
  );
  const tokenContract = new Contract(
    TOKEN_CONTRACT_ADDRESS,
    TOKEN_CONTRACT_ABI,
    signer
  );
  let tx;
  if (celoSelected) {
    tx = await exchangeContract.celoToIcebearToken(
      tokenToBeReceivedAfterSwap,
      {
        value: swapAmountWei,
      }
    );
  } else {
    tx = await tokenContract.approve(
      EXCHANGE_CONTRACT_ADDRESS,
      swapAmountWei.toString()
    );
    await tx.wait();
    tx = await exchangeContract.icebearTokenToCelo(
      swapAmountWei,
      tokenToBeReceivedAfterSwap
    );
  }
  await tx.wait();
};
