// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/access/Ownable.sol";

contract VendorToken is ERC20, Ownable {
    // 2.3 Billion total supply
    uint256 public tokenTotalSupply = 2300000000;
    // Initial Tranaction Fee : 0%
    uint256 public transferTaxPercent = 0;
    // feeAddress
    address public taxAddress;
    // ICOAddress
    address public icoAddress;
    // TimeLock of Tranaction
    mapping(address => uint256) public timeLock;
    // ICO Setting Flag
    bool public isSetICO;
    

    constructor() ERC20("Vendor", "VDR") {
        taxAddress = _msgSender();
        _mint(_msgSender(), tokenTotalSupply * (10**uint256(decimals())));
    }

    function setTaxFee(address _feeAddress, uint256 _feePercent) public onlyOwner {
        require(_feeAddress != address(0x0), "Invalid address");
        require(_feePercent >= 0);

        taxAddress = _feeAddress;
        transferTaxPercent = _feePercent;
    }

    function setICOAddress(address _icoAddress) public onlyOwner {
        require(_icoAddress != address(0x0), "Invalid address");
        require(!isSetICO);

        isSetICO = true;
        icoAddress = _icoAddress;
        if (balanceOf(_icoAddress) == 0)
        {
            uint256 icoAmount = totalSupply() * 30 / 100;
            transfer(_icoAddress, icoAmount);
        }
    }

    function setTimeLockForTranaction(address recipient, uint256 timestamp) public returns (bool){
        require(icoAddress == _msgSender());

        timeLock[recipient] = timestamp;
        return true;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(timeLock[_msgSender()] <= block.timestamp, "Tranfer is Timelocked");
        require(amount % 100 == 0);

        uint256 taxAmount = (amount * transferTaxPercent) / 100;

        if (taxAmount > 0) _transfer(_msgSender(), taxAddress, taxAmount);
        _transfer(_msgSender(), recipient, (amount - taxAmount));

        return true;
    }
}
