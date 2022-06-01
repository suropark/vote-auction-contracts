// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteProxy is Ownable {
    //
    // address public auction;

    mapping(bytes32 => address) public auction;

    constructor(address _clsAuction) {
        auction[bytes32("cls")] = _clsAuction;
    }

    function setAuction(bytes32 _govTok, address _auction) external onlyOwner {
        // auction = _auction;
        auction[_govTok] = _auction;
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
