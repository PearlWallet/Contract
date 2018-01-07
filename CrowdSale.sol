pragma solidity ^0.4.16;

contract Owned {
    address public owner;

    function Owned() public {
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

interface PltToken {
    function transfer(address receiver, uint amount) public;
    function mintToken(address receiver,uint amount) public;
}

interface ErcToken {
    
    function allowance(address src, address guy) constant public returns (uint256);

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    function approve(address _spender, uint256 _value) public;

    function balanceOf(address src) constant public returns (uint256);

    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public;
}

/**
 * Math operations with safety checks
 */
library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


contract PearlCrowdsale is Owned {

    using SafeMath for uint256;

    // PLT token unit.
    // Using same decimal value as ETH (makes ETH-PLT conversion much easier).
    // This is the same as in PLT token contract.
    uint256 public constant TOKEN_UNIT = 10 ** 18;

    // Maximum tokens offered in the sale.
    uint256 public constant MAX_TOKENS_SOLD = 500000000 * TOKEN_UNIT;

    uint256 public ethRaised;
    uint256 public price;

    uint256 public alreadyIssued;
    uint256 public deadline;
    uint256 public startTime;

    //Pearl token contact
    PltToken public pltToken;

    bool crowdsaleOpening = true;

    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    event RaisedEth(address sender,uint amount);
    /**
     * Constrctor function
     *
     * Setup the owner
     */
    function PearlCrowdsale(
        uint _startTime,
        uint _price,
        address pltTokenContractAddress
    ) public 
    {
        startTime = _startTime;
        deadline = _startTime + (1 * 33 days);
        price = _price;
        pltToken = PltToken(pltTokenContractAddress);
    }

    function setStartTime(uint _startTime,uint _deadline) onlyOwner public {
        startTime = _startTime;
        deadline = _deadline;
    }

    function setPrices(uint256 _price) onlyOwner public {
        require(_price > 0);
        price = _price;
    }

    function closeSale() onlyOwner public {
        crowdsaleOpening = false;
    }

    /**
     * Fallback function
     *
     * The function without name is the default function that is called whenever anyone sends funds to a contract
     */
    function () payable public {
        require(now > startTime);
        require(now < deadline);
        require(alreadyIssued < MAX_TOKENS_SOLD);
        require(crowdsaleOpening);
        uint256 amount = msg.value;
        uint256 rewardAmount = (amount.mul(price));
        pltToken.mintToken(msg.sender, rewardAmount);
        ethRaised = ethRaised.add(amount);
        alreadyIssued = alreadyIssued.add(rewardAmount);
        RaisedEth(msg.sender,amount);
        FundTransfer(msg.sender, amount, true);
    }

    function withdraw() onlyOwner public {
        owner.transfer(this.balance);
    }

    function withdrawToken(address tokenContractAddr) onlyOwner public {
        ErcToken token = ErcToken(tokenContractAddr);
        token.transferFrom(this,msg.sender,token.balanceOf(this));
    }

}
