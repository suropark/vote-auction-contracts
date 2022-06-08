// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IAuctionRewarder {
    function notifyReward(
        address reward,
        uint256 roundId,
        uint256 amount
    ) external;
}
