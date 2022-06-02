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
    address public clsPoolVote;
    address public auction;

    mapping(address => address) public voter;
    address[] public voters;

    uint256 public totalVoter;

    // reward
    struct Reward {
        address token;
        uint256 amount;
    }
    struct Distribution {
        Reward[] rewards;
        uint256 totalVotes;
    }
    mapping(uint256 => Distribution) public distribution; // roundId => totalCls;
    mapping(uint256 => mapping(address => bool)) public isReward;
    mapping(uint256 => mapping(address => uint256)) public rewardIndex;

    // claim
    mapping(uint256 => mapping(address => bool)) public claimed;

    modifier onlyAuction() {
        require(msg.sender == auction, "only auction contract can call this function");
        _;
    }

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

    function nodifyReward(
        address _reward,
        uint256 roundId,
        uint256 amount
    ) public onlyAuction {
        Distribution storage dist = distribution[roundId];

        bool currentReward = isReward[roundId][_reward];

        if (currentReward) {
            dist.rewards[rewardIndex[roundId][_reward]].amount += amount;
        } else {
            Reward memory reward = Reward({token: _reward, amount: amount});
            dist.rewards.push(reward);

            isReward[roundId][_reward] = true;
            rewardIndex[roundId][_reward] = dist.rewards.length - 1;
        }
    }

    function claimable(uint256 roundId) public view returns (address[] memory tokens, uint256[] memory amounts) {
        require(IClsPoolVote(clsPoolVote).latestRoundId() > roundId, "roundId is not valid");

        Distribution storage dist = distribution[roundId];

        address[] memory rewards = new address[](dist.rewards.length);
        uint256[] memory claimables = new uint256[](dist.rewards.length);

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            rewards[i] = dist.rewards[i].token;

            if (claimed[roundId][msg.sender]) {
                claimables[i] = 0;
            } else {
                if (dist.totalVotes > 0) {
                    uint256 userVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voter[msg.sender]) / 1e18) * 1e18;
                    claimables[i] = (dist.rewards[i].amount * userVotes) / dist.totalVotes;
                }
            }
        }
        return (rewards, claimables);
    }

    function claim(uint256 roundId) public {
        Distribution memory dist = distribution[roundId];

        require(dist.rewards.length > 0, "no reward");
        require(dist.totalVotes > 0, "totalVotes not calculated or no votes");
        require(claimed[roundId][msg.sender] == false, "already claimed");

        for (uint256 i = 0; i < dist.rewards.length; i++) {
            Reward memory reward = dist.rewards[i];

            uint256 userVotes = (IClsPoolVote(clsPoolVote).getClsAvailable(roundId, voter[msg.sender]) / 1e18) * 1e18;
            uint256 amt = (reward.amount * userVotes) / dist.totalVotes;

            claimed[roundId][msg.sender] == true;
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

    receive() external payable {}

    /* ========== EVENTS ========== */

    event VoterCreated(address indexed usr, address voter);
    event RewardUpdated(uint256 roundId, address reward, uint256 amount);
}
