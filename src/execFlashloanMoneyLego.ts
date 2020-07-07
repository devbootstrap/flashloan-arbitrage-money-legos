import { legos } from "@studydefi/money-legos";
import { ethers, Wallet, Contract } from "ethers";
import kovan from './kovanConfig';
require("dotenv").config()

const FlashloanMoneyLego = require("./../build/contracts/FlashloanMoneyLego.json");

const contractFlashloanMoneyLegoAddress = FlashloanMoneyLego.networks[kovan.networkID].address;

let provider = ethers.getDefaultProvider('kovan');

let walletPK = `0x${process.env.DEPLOYMENT_ACCOUNT_KEY}`

const wallet = new Wallet(walletPK, provider);

const contractFlashloanMoneyLego = new Contract(
  contractFlashloanMoneyLegoAddress,
  FlashloanMoneyLego.abi,
  wallet,
);

// Override the legos DAI mainnet address to the one on kovan
legos.erc20.dai.address = kovan.erc20.dai.address;

const main = async () => {
  const tx = await contractFlashloanMoneyLego.initateFlashLoan(
    legos.erc20.dai.address, // We would like to borrow DAI (note override to Kovan address)
    ethers.utils.parseEther("1000"), // We would like to borrow 1000 DAI (in 18 decimals)
    { gasLimit: 4000000, },
  );
  // Inspect the issued transaction
  console.log(tx);
  let receipt = await tx.wait();
  // Inspect the transaction receipt
  console.log(receipt);
  // Inspect the transaction hash
  console.log("Tx Hash: ", receipt.transactionHash);
};

// Run the arbitrage and output the result or error
main().then(console.log).catch(console.error);