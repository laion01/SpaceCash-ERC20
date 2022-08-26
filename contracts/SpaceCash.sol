// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20Capped.sol";
import "./Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract SpaceCash is ERC20Capped, Ownable {
    struct Referrer {
        uint8 count;
        address[] addrs;
    }

    mapping(address => bool) public allowBulkTransfer;
    mapping(address => bool) public isLpAddress;
    mapping(address => Referrer) public referrers;

    uint16 manageFee = 100;
    uint16 marketingFee = 40;
    uint16 devFee = 10;
    uint16 taxFee = 5;
    uint16 sellFee = 10;

    address public manageWallet;
    address public marketWallet;
    address public devWallet;

    constructor () ERC20Capped(1000*10**8) ERC20("STEST4", "ST4") payable { }

    function mint(address account, uint256 amount) public onlyOwner {
        require(amount > 0, "zero amount");
        super._mint(account, amount);
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

    function updateReferrer(address account, address ref0) internal {
        Referrer storage ref = referrers[account];
        Referrer storage ref1 = referrers[ref0];
    
        delete ref.addrs;
        if(ref.count == 0 || (ref.addrs.length > 0 && ref.addrs[0] == ref0)) {
            ref.addrs.push(ref0);
            for(uint8 i = 0 ;i < ref1.count; i++) {
                ref.addrs.push(ref1.addrs[i]);
            }
        }

        ref.count = (uint8)(ref.addrs.length);
    }

    function getReferrer(address account, uint8 id) public view returns(address){
        Referrer memory ref= referrers[account];
        require(id < ref.count, "Out of length");
        return ref.addrs[id];
    }

    function transferReferrers(address sender, address recipient, uint256 amount) internal returns(uint256, uint256){
        updateReferrer(recipient, sender);
        uint8 cnt = referrers[recipient].count;
        uint256 am; uint256 total;
        if(cnt == 0) {
            am = amount * 4 / 100;
            super.transferFrom(sender, marketWallet, am);
        } else if (cnt == 1) {
            am = amount * 2 / 100;
            super.transferFrom(sender, marketWallet, am);
            super.transferFrom(sender, referrers[recipient].addrs[0], am);
            total = am * 2;
        } else if (cnt == 2) {
            am = amount / 100;
            total = am * 4;
            super.transferFrom(sender, marketWallet, am);
            super.transferFrom(sender, referrers[recipient].addrs[0], am * 2);
            super.transferFrom(sender, referrers[recipient].addrs[1], am);
        } else if (cnt == 3) {
            am = amount / 100;
            total = am * 8;
            super.transferFrom(sender, marketWallet, am);
            super.transferFrom(sender, referrers[recipient].addrs[0], am * 4);
            super.transferFrom(sender, referrers[recipient].addrs[1], am * 2);
            super.transferFrom(sender, referrers[recipient].addrs[2], am * 1);
        } else if (cnt == 4) {
            am = amount / 400;
            total = am * 16;
            super.transferFrom(sender, marketWallet, am);
            super.transferFrom(sender, referrers[recipient].addrs[0], am * 8);
            super.transferFrom(sender, referrers[recipient].addrs[1], am * 4);
            super.transferFrom(sender, referrers[recipient].addrs[2], am * 2);
            super.transferFrom(sender, referrers[recipient].addrs[3], am * 1);
        } else if (cnt == 5) {
            am = amount / 800;
            total = am * 32;
            super.transferFrom(sender, marketWallet, am);
            super.transferFrom(sender, referrers[recipient].addrs[0], am * 16);
            super.transferFrom(sender, referrers[recipient].addrs[1], am * 8);
            super.transferFrom(sender, referrers[recipient].addrs[2], am * 4);
            super.transferFrom(sender, referrers[recipient].addrs[3], am * 2);
            super.transferFrom(sender, referrers[recipient].addrs[4], am * 1);
        }
        return (am, total);
    }

    function applyFee(address sender, address recipient, uint256 amount) internal returns(uint256) {
        if(!Address.isContract(sender) && !Address.isContract(recipient)) {
            updateReferrer(recipient, sender);
        }
        if(sender != address(this) && sender != owner())
        {
            if(isLpAddress[recipient]) {    // Sell
                uint256 burnAmount = amount * sellFee / 1000;
                amount = amount - burnAmount;
                _burn(sender, burnAmount);
            } else if(isLpAddress[sender]) {    //Buy
                if(recipient != owner()) {
                    uint256 manageAmount = amount * manageFee / 1000;
                    uint256 marketAmount;
                    uint256 referrerAmount;
                    uint256 devAmount = amount * devFee / 1000;
                    (marketAmount, referrerAmount) = transferReferrers(sender, recipient, amount);
                    amount = amount - manageAmount - marketAmount - devAmount - referrerAmount;

                    super.transferFrom(sender, manageWallet, manageAmount);
                    super.transferFrom(sender, marketWallet, marketAmount);
                    super.transferFrom(sender, devWallet, devAmount);
                }
            } else if(sender != marketWallet) {
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

    function allowBulk(bool f) public {
        allowBulkTransfer[msg.sender] = f;
    }

    function bulkTransfer(address[] calldata sender, address[] calldata recipient, uint256[] calldata amount) public onlyOwner{
        require(sender.length > 0 && sender.length == recipient.length && sender.length == amount.length, "Incorrect Data");
        for(uint256 i; i< sender.length; i++) {
            require(amount[i] > 0);
            require(sender[i] != recipient[i], "Same address");
            require(amount[i] < balanceOf(sender[i]), "Not enough token");
            require(allowBulkTransfer[sender[i]], "Bulk transfer not allowed!");


            _approve(sender[i], owner(), amount[i]);
            uint256 am = applyFee(sender[i], recipient[i], amount[i]);
            super.transferFrom(sender[i], recipient[i], am);
        }
    }
}