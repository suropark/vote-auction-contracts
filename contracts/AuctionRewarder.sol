// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/IClsPoolVote.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AuctionRewarder is Ownable {
    address public clsPoolVote = 0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9;
    address public auction;
    address public voter;
    // reward
    struct Reward {
        address token;
        uint256 amount;
    }
    struct Distribution {
        Reward[] rewards;
        mapping(address => uint256) rewardIndex; // reward
        mapping(address => bool) isReward; // reward
        mapping(address => bool) claimed; // user
    }
    mapping(uint256 => Distribution) private _distribution; // roundId => totalCls;

    mapping(uint256 => mapping(address => uint256)) public votes; // roundId, address => delegated vote
    mapping(uint256 => bool) private _votesUpdated;

    modifier onlyAuction() {
        require(msg.sender == auction, "only auction contract can call this function");
        _;
    }

    constructor() {}

    function notifyReward(
        address reward,
        uint256 roundId,
        uint256 amount
    ) public onlyAuction {
        Distribution storage dist = _distribution[roundId];

        bool rewardExists = dist.isReward[reward];

        if (rewardExists) {
            dist.rewards[dist.rewardIndex[reward]].amount += amount;
        } else {
            Reward memory newReward = Reward({token: reward, amount: amount});
            dist.rewards.push(newReward);

            dist.isReward[reward] = true;
            dist.rewardIndex[reward] = dist.rewards.length - 1;
        }
    }

    function claimable(uint256 roundId, address user) public view returns (Reward[] memory) {
        require(IClsPoolVote(clsPoolVote).latestRoundId() > roundId, "can claim after round is ended");

        Distribution storage dist = _distribution[roundId];
        Reward[] memory rewards = new Reward[](dist.rewards.length);

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            rewards[i].token = dist.rewards[i].token;

            if (dist.claimed[user]) {
                continue;
            } else {
                uint256 totalVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voter) / 1e18) * 1e18;
                if (totalVotes > 0) {
                    uint256 userVotes = votes[roundId][user];
                    rewards[i].amount = (dist.rewards[i].amount * userVotes) / totalVotes;
                }
            }
        }
        return rewards;
    }

    function claim(uint256 roundId) public {
        require(_votesUpdated[roundId], "votes not updated");
        require(IClsPoolVote(clsPoolVote).latestRoundId() > roundId, "can claim after round is ended");

        Distribution storage dist = _distribution[roundId];
        uint256 totalVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voter) / 1e18) * 1e18;

        require(dist.rewards.length > 0, "no reward");
        require(totalVotes > 0, "totalVotes not calculated or no votes");
        require(dist.claimed[msg.sender] == false, "already claimed");

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            Reward memory reward = dist.rewards[i];

            uint256 userVotes = votes[roundId][msg.sender];

            uint256 amt = (reward.amount * userVotes) / totalVotes;

            dist.claimed[msg.sender] == true;
            _transferHelper(reward.token, msg.sender, amt);
        }
    }

    function _transferHelper(
        address _token,
        address _to,
        uint256 amount
    ) internal {
        bool suc;
        if (_token == address(0)) {
            (suc, ) = _to.call{value: amount}("");
        } else {
            (suc, ) = _token.call(abi.encodeWithSignature("transfer(address,uint256)", _to, amount));
        }
        require(suc, "tranfer Failed");
    }

    /* ===== ADMIN FUNCTION ===== */

    // event 긁어서 직접 넣기
    function updateUserVotes(
        uint256 roundId,
        address[] calldata users,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(!_votesUpdated[roundId], "votes already updated");
        require(IClsPoolVote(clsPoolVote).latestRoundId() >= roundId, "");
        require(users.length == amounts.length, "user length and amount length should be same");

        for (uint256 i = 0; i < users.length; i++) {
            votes[roundId][users[i]] = amounts[i];
        }

        _votesUpdated[roundId] = true;
    }

    function setAuction(address _auction) public {
        auction = _auction;
    }

    function setVoteProxy(address _voter) public {
        voter = _voter;
    }

    event RewardUpdated(uint256 roundId, address reward, uint256 amount);
}
