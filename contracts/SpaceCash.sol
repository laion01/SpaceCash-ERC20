// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Pancakeswap/IPancakeFactory.sol";
import "./Pancakeswap/IPancakeRouter01.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "hardhat/console.sol";

contract SpaceCash is ERC20, Ownable {
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
        ERC20("SpaceCash", "SPC")
        payable
    {
        holderCount = 0;
        _mint(address(this), 1000*10**8);
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

    /**
     * @dev Function to mint tokens.
     *
     * NOTE: restricting access to owner only. See {ERC20Mintable-mint}.
     *
     * @param account The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */

    function _mint(address account, uint256 amount) internal override(ERC20) onlyOwner {
        require(amount > 0, "zero amount");
        uint256 am = balanceOf(account);
        super._mint(account, amount);

        if(am == 0)
            holderCount ++;
    }

    function withdrawLockedToken() public onlyOwner {
        require(block.timestamp > unLockTime, "Tokens Locked!");
        super.transfer(msg.sender, 250*10**8);
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     * Take transaction fee from sender and transfer fee to the transaction fee wallet.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        uint256 recipient_amount = balanceOf(recipient);

        if(isLpAddress[recipient]) {    // Sell
            uint256 burnAmount = amount * sellFee / 1000;
            amount = amount - burnAmount;
            _burn(sender, burnAmount);
        } else if(isLpAddress[sender]) {    //Buy
            uint256 manageAmount = amount * manageFee / 1000;
            uint256 marketAmount = amount * marketingFee / 1000;
            uint256 devAmount = amount * devFee / 1000;
            amount = amount - manageAmount - marketAmount - devAmount;
            
            super.transferFrom(sender, manageWallet, manageAmount);
            super.transferFrom(sender, marketWallet, marketAmount);
            super.transferFrom(sender, devWallet, devAmount);
        } else if(sender != address(this) && sender != owner()) {
            uint256 burnAmount = amount * taxFee / 1000;
            amount = amount - burnAmount;
            _burn(sender, burnAmount);
        }

        super.transferFrom(sender, recipient, amount);

        if(recipient_amount == 0)
            holderCount ++;
        if(balanceOf(sender) == 0)
            holderCount --;
        return true;
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        
        uint256 recipient_amount = balanceOf(recipient);

        if(isLpAddress[recipient]) {    // Sell
            uint256 burnAmount = amount * sellFee / 1000;
            amount = amount - burnAmount;
            _burn(msg.sender, burnAmount);
        } else if(isLpAddress[msg.sender]) {    //Buy
            uint256 manageAmount = amount * manageFee / 1000;
            uint256 marketAmount = amount * marketingFee / 1000;
            uint256 devAmount = amount * devFee / 1000;
            amount = amount - manageAmount - marketAmount - devAmount;

            super.transfer(manageWallet, manageAmount);
            super.transfer(marketWallet, marketAmount);
            super.transfer(devWallet, devAmount);
        } else if(msg.sender != address(this) && msg.sender != owner()){
            uint256 burnAmount = amount * taxFee / 1000;
            amount = amount - burnAmount;
            _burn(msg.sender, burnAmount);
        }

        super.transfer(recipient, amount);

        if(recipient_amount == 0)
            holderCount ++;
        if(balanceOf(address(msg.sender)) == 0)
            holderCount --;
        return true;
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