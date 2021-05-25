// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "openzeppelin-solidity/contracts/access/Ownable.sol";

interface IVendorToken {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function setTimeLockForTranaction(address recipient, uint256 timestamp) external returns (bool);
}

contract PresaleICO is Ownable {
    mapping(address => uint256) public deposits;
    address[] public buyers;
    uint256 public totalDeposits;
    uint256 public icoTimeLimit;
    bool public closed = false;
    IVendorToken public token;

    event Deposit(address indexed _from, uint256 _value);
    event PayoutToken(address indexed _to, uint256 _value);

    constructor() {
        icoTimeLimit = block.timestamp + 30 days;
    }

    function setVendorToken(address _vendorAddress) public onlyOwner {
        require(_vendorAddress != address(0x0), "Invalid address");
        token = IVendorToken(_vendorAddress);
    }

    function deposit() public payable {
        require(icoTimeLimit > block.timestamp, "ICO is already ended!");
        require(!closed);

        deposits[_msgSender()] += msg.value;
        totalDeposits += msg.value;
        buyers.push(_msgSender());

        emit Deposit(_msgSender(), msg.value);
    }

    function close(address _withdrawAddress) public onlyOwner {
        require(icoTimeLimit < block.timestamp, "ICO is locked by timeline!");
        require(!closed);

        closed = true;

        for (uint256 i = 0; i < buyers.length; i++) {
            address buyerAddr = buyers[i];
            uint256 buyerDeposit = deposits[buyerAddr];

            if (buyerDeposit == 0) continue;

            uint256 buyerShare = (token.balanceOf(address(this)) * buyerDeposit) / totalDeposits;
            require(token.transfer(buyerAddr, buyerShare));
            deposits[buyerAddr] = 0;
            emit PayoutToken(buyerAddr, buyerShare);
            
            if (buyerDeposit > 20 * (10**16) && buyerDeposit <= 40 * (10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 30 days);
            }
            else if (buyerDeposit > 40 * (10**16) && buyerDeposit <= 50 * (10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 60 days);
            }
            else if (buyerDeposit > 50 * (10**16) && buyerDeposit <= 75 *(10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 90 days);
            }
            else if (buyerDeposit > 75 *(10**16))
            {
                token.setTimeLockForTranaction(buyerAddr, block.timestamp + 120 days);
            }
        }

        address payable owner = payable(_withdrawAddress);
        owner.transfer(totalDeposits);
        totalDeposits = 0;
    }
}
