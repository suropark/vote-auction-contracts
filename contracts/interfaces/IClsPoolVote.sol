// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IClsPoolVote {
    struct receipt {
        uint256[] votes;
        uint256 totalUserVotes;
    }

    function name() external view returns (string memory);

    function latestRoundId() external view returns (uint256);

    function roundCount() external view returns (uint256);

    function executer() external view returns (address);

    function state(uint256 roundId) external view returns (uint8);

    function cancelVote(
        uint256 roundId,
        uint256 poolId,
        uint256 vote
    ) external;

    function getPoolIds(uint256 roundId) external view returns (uint256[] memory);

    function castVote(
        uint256 roundId,
        uint256 poolId,
        uint256 vote
    ) external;

    function getTotalClsAvailable(uint256 roundId) external view returns (uint256);

    function rounds(uint256)
        external
        view
        returns (
            uint256 maxAdminAllocPoint,
            uint256 maxUserAllocPoint,
            uint256 maxLinkAllocPoint,
            uint256 numPools,
            uint256 startBlock,
            uint256 startTime,
            uint256 endTime,
            uint256 totalUserVotes,
            uint256 totalAdminVotes,
            uint256 totalClsAmount
        );

    function getEndTime(uint256 roundId) external view returns (uint256);

    function cls() external view returns (address);

    function getClsAvailable(uint256 roundId, address voter) external view returns (uint256);

    function getStartTime(uint256 roundId) external view returns (uint256);

    function getVotablePoolIds(uint256 roundId) external view returns (uint256[] memory);

    function getReceipt(uint256 roundId, address voter) external view returns (receipt memory);
}
