// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/IClsPoolVote.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IVoteProxy {
    function execute(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool, bytes memory);
}

contract VoteAuction is Ownable, ReentrancyGuard {
    address public voter;
    address public clsPoolVote;

    address public teamWallet;

    // fee
    uint256 public fee = 400;
    uint256 public DENOMINATOR = 10000;

    // auction
    uint256 public priceFallsDuration = 1 hours;
    uint256 public basePrice = 1e17; // 1cls = 0.1klay
    uint256 public priceLowLimit = 1000;

    constructor(
        address _voter,
        address _poolVote,
        address _team
    ) {
        // poolVote = 0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9

        voter = _voter;
        clsPoolVote = _poolVote;
        teamWallet = _team;
    }

    function buyCls(uint256 amount, uint256 poolId) public payable nonReentrant {
        require(msg.value > 0, "value must be greater than 0");
        require(votableCls() > amount, "not enough votable cls");

        uint256 totalSellPrice = clsPrice() * amount;
        require(msg.value >= totalSellPrice, "value must be greater than or equal to totalSellPrice");

        _vote(poolId, amount);

        _distribute(totalSellPrice);
    }

    function _distribute(uint256 totalSellPrice) internal {
        // refund dust
        uint256 refund = msg.value - totalSellPrice;
        (bool refundSuc, ) = msg.sender.call{value: refund}("");
        require(refundSuc, "refund failed");
        // team fee
        uint256 team = (totalSellPrice * fee) / DENOMINATOR;
        (bool teamSuc, ) = teamWallet.call{value: team}("");
        require(teamSuc, "team fee failed");
    }

    function clsPrice() public view returns (uint256) {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        if (block.timestamp < IClsPoolVote(clsPoolVote).getStartTime(rId)) {
            return basePrice;
        }

        uint256 timeElapsed = block.timestamp - IClsPoolVote(clsPoolVote).getStartTime(rId);

        uint256 t = timeElapsed / priceFallsDuration;

        uint256 price = basePrice;
        for (uint256 i = 0; i < t; i++) {
            price = (price * 9000) / DENOMINATOR;
        }

        if (price < (basePrice * priceLowLimit) / DENOMINATOR) {
            price = basePrice;
        }

        // uint256 totalVotingTime = IClsPoolVote(clsPoolVote).getEndTime(rId) - IClsPoolVote(clsPoolVote).getStartTime(rId);
        return price;
    }

    function votableCls() public view returns (uint256 votable) {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();
        uint256 totalCls = (IClsPoolVote(clsPoolVote).getClsAvailable(rId, voter) / 1e18) * 1e18; // to integer

        IClsPoolVote.receipt memory receipt = IClsPoolVote(clsPoolVote).getReceipt(rId, voter);

        votable = totalCls - receipt.totalUserVotes;
    }

    function votablePools() public view returns (uint256[] memory votable) {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        votable = (IClsPoolVote(clsPoolVote).getVotablePoolIds(rId));
    }

    function _vote(uint256 poolId, uint256 voteAmt) internal {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        // 1. roundId, 2. poolId, 3. voteAmount
        (bool suc, ) = IVoteProxy(voter).execute(
            clsPoolVote,
            0,
            abi.encodeWithSignature("castVote(uint256, uint256, uint256)", rId, poolId, voteAmt)
        );

        require(suc, "vote failed");
    }

    function _vote(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) internal {
        (bool suc, ) = IVoteProxy(voter).execute(_to, _value, _data);

        require(suc, "vote failed");
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    receive() external payable {}
}
