const hre = require("hardhat");
require("color");

async function main() {

  const ERC20 = await hre.ethers.getContractFactory("SpaceCash");
  const erc20 = await ERC20.deploy();
  await erc20.deployed();
  console.log("Token Address:", erc20.address);

  await erc20.mint("0xA24E6227C1b6A88d3A4891979C9BC90f1E96912A", "100000000000");

  await erc20.setFeeWallets (
    "0x42F9dcd93DDCB82ED531A609774F6304275DeeaD",
    "0x64882E1f672113B440F3d3B706516Df02ceEE0fD",
    "0xB8D41D37E52AB93C6518F94362027a772222f4da"
  );

  await erc20.setLpAddress("0xc36442b4a4522e871399cd717abdd847ab11fe88");

  console.log("Wallets Updated");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//   # Binance testnet
// address constant WETH = 0xae13d989daC2f0dEbFf460aC112a837C89BAa7cd;
// address constant factoryAddress = 0xB7926C0430Afb07AA7DEfDE6DA862aE0Bde767bc;
// address constant routerAddress = 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3;

//   # Ropsten testnet
// address constant WETH = 0xc778417e063141139fce010982780140aa0cd5ab;
// address constant factoryAddress = 0x5c69bee701ef814a2b6a3edd4b1652cb9cc5aa6f;
// address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;