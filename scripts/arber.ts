require('dotenv').config();
import { isBytes, parseBytes32String } from "ethers/lib/utils";
import hardhat from "hardhat";
import { ethers } from "hardhat";

const DAI_ADDRESS = '0x6B175474E89094C44Da98b954EedeAC495271d0F';
const WETH_ADDRESS = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2';
const SUSHI_ROUTER = '0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F';
const UNI_ROUTER_V2 = '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D';

//const PRIV_KEY = new ethers.Wallet.fromMnemonic(process.env.MNEMONIC)
const provider = new ethers.providers.InfuraProvider('mainnet', process.env.INFURA_API_KEY);
const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

const hre = hardhat;
async function main() {
    const Arber = await hardhat.ethers.getContractFactory("Arber");
    const arber = await Arber.deploy(DAI_ADDRESS, 
                                    WETH_ADDRESS,
                                    UNI_ROUTER_V2,
                                    SUSHI_ROUTER);
    const amountToBorrow = ethers.utils.parseEther("20");
    // TODOs: 
    // * ensure contract has minimum balance for gas fees
    // * calculate gas fees
    await arber
        .flashSwap(
            WETH_ADDRESS, 
            amountToBorrow, 
            WETH_ADDRESS, 
            hre.ethers.utils.arrayify('0x00'),
            { from: wallet.address });
}

main()
    .then(console.log)
    .catch(console.log)