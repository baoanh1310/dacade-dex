import { Contract, providers, utils, BigNumber } from "ethers";
import { EXCHANGE_CONTRACT_ABI, EXCHANGE_CONTRACT_ADDRESS } from "../constants";

export const removeLiquidity = async (signer, removeLPTokensWei) => {
  const exchangeContract = new Contract(
    EXCHANGE_CONTRACT_ADDRESS,
    EXCHANGE_CONTRACT_ABI,
    signer
  );
  const tx = await exchangeContract.removeLiquidity(removeLPTokensWei);
  await tx.wait();
};

export const getTokensAfterRemove = async (
  provider,
  removeLPTokenWei,
  _celoBalance,
  icebearTokenReserve
) => {
  try {
    const exchangeContract = new Contract(
      EXCHANGE_CONTRACT_ADDRESS,
      EXCHANGE_CONTRACT_ABI,
      provider
    );
    const _totalSupply = await exchangeContract.totalSupply();
    const _removeCelo = _celoBalance.mul(removeLPTokenWei).div(_totalSupply);
    const _removeIcebear = icebearTokenReserve
      .mul(removeLPTokenWei)
      .div(_totalSupply);
    return {
      _removeCelo,
      _removeIcebear,
    };
  } catch (err) {
    console.error(err);
  }
};
