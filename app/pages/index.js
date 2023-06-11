import { BigNumber, providers, utils } from "ethers";
import Head from "next/head";
import React, { useEffect, useRef, useState } from "react";
import Web3Modal from "web3modal";
import styles from "../styles/Home.module.css";
import { addLiquidity, calculateIcebear } from "../utils/addLiquidity";
import {
  getIcebearTokensBalance,
  getCeloBalance,
  getLPTokensBalance,
  getReserveOfIcebearTokens,
} from "../utils/getAmounts";
import {
  getTokensAfterRemove,
  removeLiquidity,
} from "../utils/removeLiquidity";
import { swapTokens, getAmountOfTokensReceivedFromSwap } from "../utils/swap";
import { faucet } from "../utils/faucet";

export default function Home() {
  const [loading, setLoading] = useState(false);
  const [liquidityTab, setLiquidityTab] = useState(true);
  const zero = BigNumber.from(0);
  const [celoBalance, setCeloBalance] = useState(zero);
  const [reservedIcebear, setReservedIcebear] = useState(zero);
  const [celoBalanceContract, setCeloBalanceContract] = useState(zero);
  const [icebearBalance, setIcebearBalance] = useState(zero);
  const [lpBalance, setLPBalance] = useState(zero);
  const [addCelo, setAddCelo] = useState(zero);
  const [addIcebearTokens, setAddIcebearTokens] = useState(zero);
  const [removeCelo, setRemoveCelo] = useState(zero);
  const [removeIcebear, setRemoveIcebear] = useState(zero);
  const [removeLPTokens, setRemoveLPTokens] = useState("0");
  const [swapAmount, setSwapAmount] = useState("");
  const [tokenToBeReceivedAfterSwap, settokenToBeReceivedAfterSwap] = useState(
    zero
  );
  const [celoSelected, setCeloSelected] = useState(true);
  const web3ModalRef = useRef();
  const [walletConnected, setWalletConnected] = useState(false);

  const getAmounts = async () => {
    try {
      const provider = await getProviderOrSigner(false);
      const signer = await getProviderOrSigner(true);
      const address = await signer.getAddress();
      const _celoBalance = await getCeloBalance(provider, address);
      const _icebearBalance = await getIcebearTokensBalance(provider, address);
      const _lpBalance = await getLPTokensBalance(provider, address);
      const _reservedIcebear = await getReserveOfIcebearTokens(provider);
      const _celoBalanceContract = await getCeloBalance(provider, null, true);
      setCeloBalance(_celoBalance);
      setIcebearBalance(_icebearBalance);
      setLPBalance(_lpBalance);
      setReservedIcebear(_reservedIcebear);
      setReservedIcebear(_reservedIcebear);
      setCeloBalanceContract(_celoBalanceContract);
    } catch (err) {
      console.error(err);
    }
  };

  const _swapTokens = async () => {
    try {
      const swapAmountWei = utils.parseEther(swapAmount);
      if (!swapAmountWei.eq(zero)) {
        const signer = await getProviderOrSigner(true);
        setLoading(true);
        await swapTokens(
          signer,
          swapAmountWei,
          tokenToBeReceivedAfterSwap,
          celoSelected
        );
        setLoading(false);
        await getAmounts();
        setSwapAmount("");
      }
    } catch (err) {
      console.error(err);
      setLoading(false);
      setSwapAmount("");
    }
  };

  const _faucet = async () => {
    try {
      const signer = await getProviderOrSigner(true);
      setLoading(true);
      await faucet(signer);
      setLoading(false);
      await getAmounts();
    } catch (err) {
      console.error(err);
      setLoading(false);
    }
  }

  const _getAmountOfTokensReceivedFromSwap = async (_swapAmount) => {
    try {
      const _swapAmountWEI = utils.parseEther(_swapAmount.toString());
      if (!_swapAmountWEI.eq(zero)) {
        const provider = await getProviderOrSigner();
        const _celoBalance = await getCeloBalance(provider, null, true);
        const amountOfTokens = await getAmountOfTokensReceivedFromSwap(
          _swapAmountWEI,
          provider,
          celoSelected,
          _celoBalance,
          reservedIcebear
        );
        settokenToBeReceivedAfterSwap(amountOfTokens);
      } else {
        settokenToBeReceivedAfterSwap(zero);
      }
    } catch (err) {
      console.error(err);
    }
  };

  const _addLiquidity = async () => {
    try {
      const addCeloWei = utils.parseEther(addCelo.toString());
      if (!addIcebearTokens.eq(zero) && !addCeloWei.eq(zero)) {
        const signer = await getProviderOrSigner(true);
        setLoading(true);
        await addLiquidity(signer, addIcebearTokens, addCeloWei);
        setLoading(false);
        setAddIcebearTokens(zero);
        await getAmounts();
      } else {
        setAddIcebearTokens(zero);
      }
    } catch (err) {
      console.error(err);
      setLoading(false);
      setAddIcebearTokens(zero);
    }
  };

  const _removeLiquidity = async () => {
    try {
      const signer = await getProviderOrSigner(true);
      const removeLPTokensWei = utils.parseEther(removeLPTokens);
      setLoading(true);
      await removeLiquidity(signer, removeLPTokensWei);
      setLoading(false);
      await getAmounts();
      setRemoveIcebear(zero);
      setRemoveCelo(zero);
    } catch (err) {
      console.error(err);
      setLoading(false);
      setRemoveIcebear(zero);
      setRemoveCelo(zero);
    }
  };

  const _getTokensAfterRemove = async (_removeLPTokens) => {
    try {
      const provider = await getProviderOrSigner();
      const removeLPTokenWei = utils.parseEther(_removeLPTokens);
      const _celoBalance = await getCeloBalance(provider, null, true);
      const icebearTokenReserve = await getReserveOfIcebearTokens(provider);
      const { _removeCelo, _removeIcebear } = await getTokensAfterRemove(
        provider,
        removeLPTokenWei,
        _celoBalance,
        icebearTokenReserve
      );
      setRemoveCelo(_removeCelo);
      setRemoveIcebear(_removeIcebear);
    } catch (err) {
      console.error(err);
    }
  };

  const connectWallet = async () => {
    try {
      await getProviderOrSigner();
      setWalletConnected(true);
    } catch (err) {
      console.error(err);
    }
  };

  const getProviderOrSigner = async (needSigner = false) => {
    const provider = await web3ModalRef.current.connect();
    const web3Provider = new providers.Web3Provider(provider);

    const { chainId } = await web3Provider.getNetwork();
    if (chainId !== 44787) {
      window.alert("Change the network to Alfajores");
      throw new Error("Change network to Alfajores");
    }

    if (needSigner) {
      const signer = web3Provider.getSigner();
      return signer;
    }
    return web3Provider;
  };

  useEffect(() => {
    if (!walletConnected) {
      web3ModalRef.current = new Web3Modal({
        network: "alfajores",
        providerOptions: {},
        disableInjectedProvider: false,
      });
      connectWallet();
      getAmounts();
    }
  }, [walletConnected]);

  const round = (num) => {
    const arr = num.split('.');
    const firstPart = arr[0];
    const secondPart = arr[1].substring(0, 2);
    return firstPart + '.' + secondPart;
  }

  const renderButton = () => {
    if (!walletConnected) {
      return (
        <button onClick={connectWallet} className={styles.button}>
          Connect your wallet
        </button>
      );
    }

    if (loading) {
      return <button className={styles.button}>Loading...</button>;
    }

    if (liquidityTab) {
      return (
        <div>
          <div className={styles.description}>
            You have:
            <br />
            {round(utils.formatEther(icebearBalance))} ICB Tokens
            <br />
            {round(utils.formatEther(celoBalance))} CELO
            <br />
            {round(utils.formatEther(lpBalance))}  ICB-LP tokens
          </div>
          <div>
            {utils.parseEther(reservedIcebear.toString()).eq(zero) ? (
              <div>
                <input
                  type="number"
                  placeholder="Amount of CELO"
                  onChange={(e) => setAddCelo(e.target.value || "0")}
                  className={styles.input}
                />
                <input
                  type="number"
                  placeholder="Amount of ICB"
                  onChange={(e) =>
                    setAddIcebearTokens(
                      BigNumber.from(utils.parseEther(e.target.value || "0"))
                    )
                  }
                  className={styles.input}
                />
                <button className={styles.button1} onClick={_addLiquidity}>
                  Add
                </button>
              </div>
            ) : (
              <div>
                <input
                  type="number"
                  placeholder="Amount of Celo"
                  onChange={async (e) => {
                    setAddCelo(e.target.value || "0");
                    const _addIcebearTokens = await calculateIcebear(
                      e.target.value || "0",
                      celoBalanceContract,
                      reservedIcebear
                    );
                    setAddIcebearTokens(_addIcebearTokens);
                  }}
                  className={styles.input}
                />
                <div className={styles.inputDiv}>
                  {`You will need ${round(utils.formatEther(addIcebearTokens))} ICB`}
                </div>
                <button className={styles.button1} onClick={_addLiquidity}>
                  Add
                </button>
              </div>
            )}
            <div>
              <input
                type="number"
                placeholder="Amount of LP Tokens"
                onChange={async (e) => {
                  setRemoveLPTokens(e.target.value || "0");
                  await _getTokensAfterRemove(e.target.value || "0");
                }}
                className={styles.input}
              />
              <div className={styles.inputDiv}>
                {`You will get ${utils.formatEther(removeIcebear)} ICB and ${round(utils.formatEther(removeCelo))} CELO`}
              </div>
              <button className={styles.button1} onClick={_removeLiquidity}>
                Remove
              </button>
            </div>
          </div>
        </div>
      );
    } else {
      return (
        <div>
          <input
            type="number"
            placeholder="Amount"
            onChange={async (e) => {
              setSwapAmount(e.target.value || "");
              await _getAmountOfTokensReceivedFromSwap(e.target.value || "0");
            }}
            className={styles.input}
            value={swapAmount}
          />
          <select
            className={styles.select}
            name="dropdown"
            id="dropdown"
            onChange={async () => {
              setCeloSelected(!celoSelected);
              await _getAmountOfTokensReceivedFromSwap(0);
              setSwapAmount("");
            }}
          >
            <option value="celo">Celo</option>
            <option value="icebearToken">ICB</option>
          </select>
          <br />
          <div className={styles.inputDiv}>
            {celoSelected
              ? `You will get ${round(utils.formatEther(
                  tokenToBeReceivedAfterSwap
                ))} ICB`
              : `You will get ${round(utils.formatEther(
                  tokenToBeReceivedAfterSwap
                ))} CELO`}
          </div>
          <button className={styles.button1} onClick={_swapTokens}>
            Swap
          </button>
        </div>
      );
    }
  };

  return (
    <div>
      <Head>
        <title>Icebear DEX</title>
        <meta name="description" content="Icebear DEX" />
        <link rel="icon" href="/favicon.ico" />
      </Head>
      <div className={styles.main}>
        <div>
          <h1 className={styles.title}>Welcome to Icebear Exchange!</h1>
          <div className={styles.description}>
            Exchange CELO &#60;&#62; ICB Tokens
          </div>
          <div>
            <button
              className={styles.button}
              onClick={() => {
                setLiquidityTab(true);
              }}
            >
              Liquidity
            </button>
            <button
              className={styles.button}
              onClick={() => {
                setLiquidityTab(false);
              }}
            >
              Swap
            </button>
            <button
              className={styles.button}
              onClick={_faucet}
            >
              Faucet ICB
            </button>
          </div>
          {renderButton()}
        </div>
        <div>
          <img className={styles.image} src="./icebear.gif" />
        </div>
      </div>

      <footer className={styles.footer}>
        Made with &#10084; by Icebear
      </footer>
    </div>
  );
}
