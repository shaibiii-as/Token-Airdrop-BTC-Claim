// File: contracts/PTPMock.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract PTPMock is ERC20, Ownable {
    address public rewardMinter;

    modifier onlyMinter() {
        require(msg.sender == rewardMinter, "Invalid Caller");
        _;
    }

    constructor() ERC20("10Pantacles", "PTP") {}

    function setRewardMinter(address _minter) public onlyOwner {
        rewardMinter = _minter;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    function mintAmount(address _to, uint256 _amount) public onlyMinter {
        require(_to != address(0), "invalid address");
        require(_amount > 0, "Amount must be more than Zero");
        _mint(_to, _amount);
    }
}
