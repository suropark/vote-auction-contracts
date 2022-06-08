// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IVoterFactory {
    function clsPoolVote() external view returns (address);

    function auction() external view returns (address);

    function voter(address _usr) external view returns (address voteProxy);

    function totalVoter() external view returns (uint256);

    function voterLength() external view returns (uint256);

    function getTotalCls() external view returns (uint256);

    function getRemainingCls() external view returns (uint256);

    function getUsedCls() external view returns (uint256);

    function vote()
}
