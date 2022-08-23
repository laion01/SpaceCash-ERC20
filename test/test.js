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

    const ERC20 = await hre.ethers.getContractFactory("Full_ERC20");
    erc20 = await ERC20.deploy("CryptoWarriors", "CWS", "1000000000000000000000000");
    await erc20.deployed();
    console.log("Token Address:", erc20.address);

    
  });

  it("Deploy ICO Contract", async function () {
    var releaseTime = Math.floor(new Date().getTime()/1000) + 3600 * 24 * 30;

    const ERC20_ICO = await hre.ethers.getContractFactory("ERC20_ICO");
    ico = await ERC20_ICO.deploy(erc20.address, "0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684", releaseTime);
    await ico.deployed();
    console.log("ERC20-ICO Address:", ico.address);

    await erc20.setICOAddress(ico.address);
    await ico.setToken(erc20.address);
  });
});