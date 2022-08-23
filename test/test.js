const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const util = require('util')

var factoryContract = null;
var erc20, ico;
var owner, addr1;


const timer = util.promisify(setTimeout);

describe("Test Token Contract", function () {
  it("Deploy Token", async function () {
    [owner, addr1] = await ethers.getSigners();
    owner_addr = owner.address;

    const ERC20 = await hre.ethers.getContractFactory("SpaceCash");
    const erc20 = await ERC20.deploy();
    await erc20.deployed();
    console.log("Token Address:", erc20.address);

    await erc20.mint(erc20.address, "100000000000");

    await erc20.setFeeWallets (
      "0x42F9dcd93DDCB82ED531A609774F6304275DeeaD",
      "0x64882E1f672113B440F3d3B706516Df02ceEE0fD",
      "0xB8D41D37E52AB93C6518F94362027a772222f4da"
    );
  });
});