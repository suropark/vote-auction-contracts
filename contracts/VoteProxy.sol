// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteProxy is Ownable {
    //
    address public auction;

    function setAuction(address _auction) external onlyOwner {
        auction = _auction;
    }

    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlyOwner returns (bool, bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        return (success, result);
    }
}
