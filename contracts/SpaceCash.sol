// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./Pancakeswap/IPancakeFactory.sol";
import "./Pancakeswap/IPancakeRouter01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "hardhat/console.sol";

contract SpaceCash is ERC20Capped, Ownable {
    mapping(address => bool) public isLpAddress;
    uint256 public unLockTime;
    uint256 public holderCount;

    uint16 manageFee = 100;
    uint16 marketingFee = 40;
    uint16 devFee = 10;
    uint16 taxFee = 5;
    uint16 sellFee = 10;

    address public manageWallet;
    address public marketWallet;
    address public devWallet;

    constructor ()
        ERC20Capped(1000*10**8)
        ERC20("SpaceCash", "SPC")
        payable
    {
        holderCount = 0;
        unLockTime = block.timestamp + 365 days;
    }
    
    receive() payable external {}
    fallback() payable external {}

    function createLiquidity(address factoryAddr, address routerAddr, address tokenAddr, uint256 amountA, uint256 amountB) public payable onlyOwner {
        IPancakeFactory factoryContract = IPancakeFactory(factoryAddr);
        IPancakeRouter01 routerContract = IPancakeRouter01(routerAddr);        
        _approve(address(this), routerAddr, amountA);

        if(msg.value == 0) {
            IERC20 tokenB = IERC20(tokenAddr);
            tokenB.approve(routerAddr, amountB);
            routerContract.addLiquidity(address(this), tokenAddr, amountA, amountB, amountA, amountB, msg.sender, block.timestamp + 600);
        } else {
            routerContract.addLiquidityETH{value: msg.value}(address(this), amountA, amountA, msg.value, msg.sender, block.timestamp + 600);
        }
        address pairAddr = factoryContract.getPair(address(this), tokenAddr);
        setLpAddress(pairAddr, true);
        setLpAddress(routerAddr, true);
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(amount > 0, "zero amount");
        super._mint(account, amount);
    }

    function withdrawLockedToken() public onlyOwner {
        require(block.timestamp > unLockTime, "Tokens Locked!");
        super.transfer(msg.sender, 250*10**8);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        amount = applyFee(sender, recipient, amount);
        super.transferFrom(sender, recipient, amount);
        return true;
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        amount = applyFee(msg.sender, recipient, amount);
        super.transfer(recipient, amount);
        return true;
    }

    function applyFee(address sender, address recipient, uint256 amount) internal returns(uint256) {
        if(sender != address(this) && sender != owner())
        {
            if(isLpAddress[recipient]) {    // Sell
                uint256 burnAmount = amount * sellFee / 1000;
                amount = amount - burnAmount;
                _burn(sender, burnAmount);
            } else if(isLpAddress[sender]) {    //Buy
                uint256 manageAmount = amount * manageFee / 1000;
                uint256 marketAmount = amount * marketingFee / 1000;
                uint256 devAmount = amount * devFee / 1000;
                amount = amount - manageAmount - marketAmount - devAmount;

                super.transfer(manageWallet, manageAmount);
                super.transfer(marketWallet, marketAmount);
                super.transfer(devWallet, devAmount);
            } else {
                uint256 burnAmount = amount * taxFee / 1000;
                amount = amount - burnAmount;
                _burn(sender, burnAmount);
            }
        }
        return amount;
    }

    function setFeeWallets(address manager, address market, address dev) public onlyOwner {
        manageWallet = manager;
        marketWallet = market;
        devWallet = dev;
    }

    function setLpAddress(address addr, bool f) public onlyOwner {
        isLpAddress[addr] = f;
    }
}