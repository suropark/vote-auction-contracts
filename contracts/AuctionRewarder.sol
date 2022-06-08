// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "./interfaces/IClsPoolVote.sol";
import "./interfaces/IVoterFactory.sol";

contract AuctionRewarder {
    address public clsPoolVote = 0x6Ee1A9D6C2C9E4F08eFB82372bAD7ffa89fe99C9;
    address public auction;
    address public voterFactory;
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
        uint256 totalVotes;
    }
    mapping(uint256 => Distribution) public distribution; // roundId => totalCls;

    modifier onlyAuction() {
        require(msg.sender == auction, "only auction contract can call this function");
        _;
    }

    function nodifyReward(
        address reward,
        uint256 roundId,
        uint256 amount
    ) public onlyAuction {
        Distribution storage dist = distribution[roundId];

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

        Distribution storage dist = distribution[roundId];
        Reward[] memory rewards = new Reward[](dist.rewards.length);

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            rewards[i].token = dist.rewards[i].token;

            if (dist.claimed[msg.sender]) {
                continue;
            } else {
                if (dist.totalVotes > 0) {
                    uint256 userVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(
                        roundId,
                        IVoterFactory(voterFactory).voter(user)
                    ) / 1e18) * 1e18;
                    rewards[i].amount = (dist.rewards[i].amount * userVotes) / dist.totalVotes;
                }
            }
        }
        return rewards;
    }

    function claim(uint256 roundId) public {
        require(IClsPoolVote(clsPoolVote).latestRoundId() > roundId, "can claim after round is ended");

        Distribution storage dist = distribution[roundId];
        require(dist.rewards.length > 0, "no reward");
        require(dist.totalVotes > 0, "totalVotes not calculated or no votes");
        require(dist.claimed[msg.sender] == false, "already claimed");

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            Reward memory reward = dist.rewards[i];

            uint256 userVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(
                roundId,
                IVoterFactory(voterFactory).voter(msg.sender)
            ) / 1e18) * 1e18;

            uint256 amt = (reward.amount * userVotes) / dist.totalVotes;

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

    event RewardUpdated(uint256 roundId, address reward, uint256 amount);
}
