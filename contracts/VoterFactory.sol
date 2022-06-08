// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./VoteProxy.sol";
import "./interfaces/IClsPoolVote.sol";

// for reward Distributing

// 하나의 delgatee로 voter 역할을 하게 하면 auction 과정은 손 쉬우나
//  delegate한 address, vote amount를 온체인에서 라운드마다 계산할 수 있는 방법이 떠오르지 않음
// 각각의 address에 delegate 할 수 있는 contract를 deploy하고 factory에서 이를 관리하는 방식으로 하면
// address[] 를 순회하면서 총 votes 를 계산할 수 있고, 각각 유저의 vote amount를 추적할 수 있다
// vote 판매 대금을 분배하기 위해서 생각해본 방법 ?
// voterFactory를 쓰는 voteAuction을 만들어야 할듯

// 1. voterFactory에서 voter contract deploy(각각의 유저마다)
// 2. 유저는 각자의 voter에 delegate
// 3. voteAuction에서는 cls 개수를 합쳐서 판매 및 계산
contract VoterFactory {
    address public clsPoolVote = 0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9;
    address public auction;

    mapping(address => address) public voter;
    address[] public voters;
    uint256 public totalVoter;

    /* */

    function createVoter() public {
        require(voter[msg.sender] == address(0), "already created");

        address newVoter = address(new VoteProxy());
        voter[msg.sender] = newVoter;

        totalVoter++;
        voters.push(newVoter);

        emit VoterCreated(msg.sender, newVoter);
    }

    function voterLength() public view returns (uint256) {
        return voters.length;
    }

    function getTotalCls() public view returns (uint256) {
        uint256 totalCls = 0;
        uint256 roundId = IClsPoolVote(clsPoolVote).latestRoundId();

        for (uint256 i = 0; i < voters.length; i++) {
            totalCls += (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voters[i]) / 1e18) * 1e18; // to integer
        }
        return totalCls;
    }

    function getRemainingCls() public view returns (uint256) {
        uint256 remaining = 0;
        uint256 roundId = IClsPoolVote(clsPoolVote).latestRoundId();

        for (uint256 i = 0; i < voters.length; i++) {
            uint256 totalCls = (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voters[i]) / 1e18) * 1e18; // to integer

            IClsPoolVote.receipt memory receipt = IClsPoolVote(clsPoolVote).getReceipt(roundId, voters[i]);

            remaining = remaining + totalCls - receipt.totalUserVotes;
        }
        return remaining;
    }

    function getUsedCls() public view returns (uint256) {
        uint256 used = 0;
        uint256 roundId = IClsPoolVote(clsPoolVote).latestRoundId();

        for (uint256 i = 0; i < voters.length; i++) {
            IClsPoolVote.receipt memory receipt = IClsPoolVote(clsPoolVote).getReceipt(roundId, voters[i]);

            used = used + receipt.totalUserVotes;
        }
        return used;
    }

    /* Vote */
    function vote(
        uint256 roundId,
        uint256 poolId,
        uint256 voteAmt
    ) external returns (uint256 voted) {
        require(msg.sender == auction, "not auction");


        uint256 voted;
    for (uint256 i = 0; i < totalVoter; i++) {
        
        (bool suc, ) = VoteProxy(voter).execute(
            clsPoolVote,
            0,
            abi.encodeWithSignature("castVote(uint256, uint256, uint256)", roundId, poolId, voteAmt)
        );
        require(suc, "vote failed");
    }

    }

    /* ====================== ADMIN FUNCITON ====================== */

    function setClsPoolVote(address _clsPoolVote) public {
        clsPoolVote = _clsPoolVote;
    }

    function setAuction(address _auction) public {
        auction = _auction;
    }

    receive() external payable {}

    /* ========== EVENTS ========== */

    event VoterCreated(address indexed usr, address voter);
}
