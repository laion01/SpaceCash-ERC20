const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const { fileURLToPath } = require("url");
const util = require('util')

var erc20;
var owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, addr10;


const timer = util.promisify(setTimeout);

describe("Test Token Contract", function () {
  it("Deploy Token", async function () {
    [owner, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8, addr9, addr10] = await ethers.getSigners();
    owner_addr = owner.address;

    const ERC20 = await hre.ethers.getContractFactory("SpaceCash");
    erc20 = await ERC20.deploy();
    await erc20.deployed();
    console.log("Token Address:", erc20.address);

    await erc20.mint(owner.address, "100000000000");

  });

  it("Update fee wallets", async function () {
    await erc20.setFeeWallets (addr8.address, addr9.address, addr10.address);
  });

  it("Transfer Test", async function () {
    erc20.transfer(addr1.address, "10000"); // 100
    erc20.transfer(addr2.address, "10000"); // 100
    erc20.connect(addr2).transfer(addr3.address, "8000"); //100 -80
    erc20.connect(addr3).transfer(addr4.address, "7000"); // 80 * 99.5 - 70 = 9.6
    erc20.connect(addr4).transfer(addr5.address, "6000"); // 70 * 99.5 - 60 = 9.65
    erc20.connect(addr5).transfer(addr6.address, "5000"); // 60 * 99.5 - 50 = 9.7
    erc20.connect(addr6).transfer(addr7.address, "4000"); // 50 * 99.5 - 40 = 9.75

    expect(await erc20.balanceOf(addr1.address)).to.equal("10000");
    expect(await erc20.balanceOf(addr2.address)).to.equal("2000");
    expect(await erc20.balanceOf(addr3.address)).to.equal("960");
    expect(await erc20.balanceOf(addr4.address)).to.equal("965");
    expect(await erc20.balanceOf(addr5.address)).to.equal("970");
    expect(await erc20.balanceOf(addr6.address)).to.equal("975");
  });

  it("Referrer Test", async function () {
    expect(await erc20.referrers(addr6.address)).to.equal(5);
    expect(await erc20.getReferrer(addr6.address, 0)).to.equal(addr5.address);
    expect(await erc20.getReferrer(addr6.address, 4)).to.equal(owner.address);
    expect(await erc20.getReferrer(addr6.address, 2)).to.equal(addr3.address);

    expect(await erc20.referrers(addr4.address)).to.equal(3);
    expect(await erc20.getReferrer(addr4.address, 2)).to.equal(owner.address);
    expect(await erc20.getReferrer(addr4.address, 1)).to.equal(addr2.address);
  });

  it("Accept Bulk transfer", async function () {
    erc20.allowBulk(true);
    erc20.connect(addr2).allowBulk(true);
    erc20.connect(addr3).allowBulk(true);
  });

  it("Transfer 100", async function () {
    await erc20.transfer(addr2.address, "100000");
    const senders = [];
    const receivers = [];
    const amounts = [];
    for(let i = 0 ;i < 100; i++) {
      senders.push(addr2.address);
      receivers.push(addr3.address);
      amounts.push("1000");
    }
    const data = await erc20.bulkTransfer(senders, receivers, amounts);
    // console.log(data);
  });

  it("Transfer 300", async function () {
    expect(await erc20.allowBulkTransfer(owner.address)).to.equal(true);
    const senders = [];
    const receivers = [];
    const amounts = [];
    for(let i = 0 ;i < 300; i++) {
      senders.push(owner.address);
      receivers.push(addr3.address);
      amounts.push("1000");
    }
    const data = await erc20.bulkTransfer(senders, receivers, amounts);
  });
});