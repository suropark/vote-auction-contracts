// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/IClsRewardController.sol";

interface IVoteProxy {

    function execute(address _to, uint256 _value, bytes calldata _data) external returns (bool, bytes memory);
}

contract VoteAuction {


    address public voter;
    address public clsRewardController;


    uint256 fee = 400;
    uint256 DENOMINATOR = 10000;

    uint256 basePrice ;







    function availableVote() public view returns (uint256 availVote) {

        uint256 rId = IClsRewardController(clsRewardController).latestRoundId();

        availVote =  IClsRewardController(clsRewardController).getClsAvailable(rId, voter);


    }
    




    function _vote(uint256 roundId, uint256 poolId,  uint256 voteAmt) internal {
        // 1. roundId, 2. poolId, 3. voteAmount
        (bool suc,) =IVoteProxy(voter).execute(clsRewardController, 0, abi.encodeWithSignature("castVote(uint256, uint256, uint256)", roundId, poolId, voteAmt));

        require(suc, "vote failed");
    }

    function _vote(address _to, uint256 _value, bytes calldata _data) internal {
        
       (bool suc,) = IVoteProxy(voter).execute(_to, _value, _data);

        require(suc, "vote failed");
    }
}