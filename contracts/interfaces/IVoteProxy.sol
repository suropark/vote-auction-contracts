// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IVoteProxy {
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}
