pragma solidity ^0.4.16;

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface token {
    function transfer(address receiver, uint amount) public;
    function mintToken(address receiver,uint amount) public;
}

interface EosToken {
    
    function allowance(address src, address guy) constant public returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public;

    function balanceOf(address src) constant public returns (uint256);

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public;
}

contract APearlCrowdsale is owned {


    // PLT token unit.
    // Using same decimal value as ETH (makes ETH-PLT conversion much easier).
    // This is the same as in PLT token contract.
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    // Maximum tokens offered in the sale.
    uint256 public constant MAX_TOKENS_SOLD = 5000000000 * TOKEN_UNIT;

    uint public ethRaised;
    uint public eosRaised;
    
    uint public eosPrice;
    uint public ethPrice;

    uint public alreadyIssued;
    uint public deadline;
    uint public startTime;

    //eostoken contact
    EosToken public eosToken;
    //Pearl token contact
    token public tokenReward;

    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event RaisedEth(address sender,uint amount);
    event RaisedEos(address sender,uint amount);
    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function APearlCrowdsale(
        uint _startTime,
        address saledTokenContractAddress,
        address eosContractAddress
    ) public 
    {
        startTime = _startTime;
        deadline = _startTime + 1 * 1 days;
        ethPrice = 0.0002 * 1 ether;
        eosPrice = 0.003 * 1 ether;
        tokenReward = token(saledTokenContractAddress);
        eosToken = EosToken(eosContractAddress);
    }


    function setPrices(uint256 _ethPrice, uint256 _eosPrice) onlyOwner public {
        require(_eosPrice > 0 && _ethPrice > 0);
        ethPrice = _ethPrice * 1 ether;
        eosPrice = _eosPrice * 1 ether;
    }
    
    modifier afterDeadline() { 
        if (now >= deadline) 
        _; 
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(block.timestamp > startTime);
        require(block.timestamp < deadline);
        require(alreadyIssued < MAX_TOKENS_SOLD);

        uint amount = msg.value;
        ethRaised += amount;
        uint rewardAmount = (amount / ethPrice) * TOKEN_UNIT;
        alreadyIssued += rewardAmount;
        tokenReward.mintToken(msg.sender, rewardAmount);
        RaisedEth(msg.sender,amount);
        FundTransfer(msg.sender, amount, true);
    }

    function withdrawAsset() onlyOwner public {
        owner.transfer(this.balance);
        eosToken.transferFrom(this,owner,eosToken.balanceOf(this));
    }

    /**
     * Check if goal was reached
     *
     * Checks if the goal or time limit has been reached and ends the campaign
     */
    function checkGoalReached() afterDeadline public {
        if (alreadyIssued >= MAX_TOKENS_SOLD) {
            fundingGoalReached = true;
        }
        crowdsaleClosed = true;
    }

}
