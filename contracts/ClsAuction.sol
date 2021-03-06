// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./VoteProxy.sol";
import "./interfaces/IClsPoolVote.sol";
import "./interfaces/IAuctionRewarder.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// CLS Vote Auction - DutchAuction.
contract VoteAuction is Ownable, ReentrancyGuard {
    address public clsPoolVote;
    address public auctionRewarder;
    address public voter;
    // fee
    address public teamWallet;
    uint256 public fee = 400;
    uint256 public constant DENOMINATOR = 10000;

    // auction
    uint256 public priceFallsDuration = 6 hours;
    uint256 public basePrice = 1e17; // 1cls = 0.1klay
    uint256 public priceLowLimit = 1000;

    constructor(address _team) {
        clsPoolVote = 0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9;
        teamWallet = _team;

        voter = address(new VoteProxy());
    }

    function buyCls(
        uint256 amount,
        uint256 poolId,
        bool fillAmount
    ) public payable nonReentrant {
        require(msg.value > 0, "value must be greater than 0");

        uint256 remain = remainingVote();
        if (fillAmount) {
            require(remain > amount, "not enough vote");
        }

        uint256 voteAmt = remain > amount ? amount : remain - amount;
        _buyCls(voteAmt, poolId);
    }

    function _buyCls(uint256 amount, uint256 poolId) internal {
        uint256 currentPrice = clsPrice();

        uint256 totalSellPrice = currentPrice * amount;
        require(msg.value >= totalSellPrice, "value must be greater than or equal to totalSellPrice");

        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        _vote(rId, poolId, amount);

        _distribute(rId, totalSellPrice);

        emit VoteSold(msg.sender, rId, poolId, amount, totalSellPrice);
    }

    function _distribute(uint256 roundId, uint256 soldPrice) internal {
        // refund dust
        uint256 refund = msg.value - soldPrice;
        (bool refundSuc, ) = msg.sender.call{value: refund}("");
        require(refundSuc, "refund failed");
        // team fee
        uint256 team = (soldPrice * fee) / DENOMINATOR;
        (bool teamSuc, ) = teamWallet.call{value: team}("");
        require(teamSuc, "team fee failed");
        // reward
        (bool rewardSuc, ) = auctionRewarder.call{value: payable(address(this)).balance}("");
        require(rewardSuc, "reward failed");
        IAuctionRewarder(auctionRewarder).notifyReward(address(0), roundId, address(this).balance);
    }

    function _vote(
        uint256 roundId,
        uint256 poolId,
        uint256 voteAmt
    ) internal {
        (bool suc, ) = VoteProxy(voter).execute(
            clsPoolVote,
            0,
            abi.encodeWithSignature("castVote(uint256, uint256, uint256)", roundId, poolId, voteAmt)
        );
        require(suc, "vote failed");
    }

    /* ===== VIEW FUNCTION ===== */
    function clsPrice() public view returns (uint256) {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        if (block.timestamp < IClsPoolVote(clsPoolVote).getStartTime(rId)) {
            return basePrice;
        }

        uint256 timeElapsed = block.timestamp - IClsPoolVote(clsPoolVote).getStartTime(rId);

        uint256 t = timeElapsed / priceFallsDuration;

        uint256 price = basePrice;
        for (uint256 i = 0; i < t; i++) {
            price = (price * 9000) / DENOMINATOR; // 10%??? ??????
        }

        if (price < (basePrice * priceLowLimit) / DENOMINATOR) {
            price = basePrice;
        }

        return price;
    }

    function votablePools() public view returns (uint256[] memory votable) {
        uint256 rId = IClsPoolVote(clsPoolVote).latestRoundId();

        votable = (IClsPoolVote(clsPoolVote).getVotablePoolIds(rId));
    }

    function totalVote() public view returns (uint256) {
        uint256 roundId = IClsPoolVote(clsPoolVote).latestRoundId();

        return (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voter) / 1e18) * 1e18; // to integer
    }

    function remainingVote() public view returns (uint256) {
        uint256 roundId = IClsPoolVote(clsPoolVote).latestRoundId();

        IClsPoolVote.receipt memory receipt = IClsPoolVote(clsPoolVote).getReceipt(roundId, voter);

        return totalVote() - receipt.totalUserVotes;
    }

    /* ===== ADMIN FUNCTION ===== */

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setTeamWallet(address _teamWallet) public onlyOwner {
        teamWallet = _teamWallet;
    }

    function setauctionRewarder(address _auctionRewarder) public onlyOwner {
        auctionRewarder = _auctionRewarder;
    }

    function setPriceFallsDuration(uint256 _priceFallsDuration) public onlyOwner {
        priceFallsDuration = _priceFallsDuration;
    }

    function setFee(uint256 _fee) public onlyOwner {
        require(_fee <= 10000, "fee must be less than 1000 = 10% ");
        fee = _fee;
    }

    receive() external payable {}

    /* ========== EVENTS ========== */

    event VoteSold(address indexed buyer, uint256 roundId, uint256 poolId, uint256 voteAmount, uint256 sellPrice);
}
