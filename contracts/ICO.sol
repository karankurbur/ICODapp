pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./SpaceCoin.sol";

contract ICO {
    enum State { PRIVATE_SALE, GENERAL_SALE, OPEN_SALE, COMPLETED }

    address public owner;
    address public tokenAddress;
    bool public paused;
    State public state;
    uint public totalContributions = 0;

    mapping (address => uint) public contributions;
    mapping (address => uint) public redeemedETH;
    mapping (address => bool) public whitelisted;

    uint ICO_CONTRIBUTION_LIMIT = 30000 ether;
    uint PRIVATE_SALE_LIMIT = 15000 ether;

    uint PRIVATE_SALE_INDIVIDUAL_LIMIT = 1500 ether;
    uint GENERAL_SALE_INDIVIDUAL_LIMIT = 1000 ether;

    uint TOKEN_REDEMPTION_MULTIPLIER = 5;

    constructor(address[] memory whitelist) {
        owner = msg.sender;
        paused = false;
        state = State.PRIVATE_SALE;

        for(uint i = 0; i < whitelist.length; i++) {
            whitelisted[whitelist[i]] = true;
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function isTokenAddressSet() public view returns (bool) {
        return tokenAddress != address(0);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(!isTokenAddressSet(), "token address already set");
        tokenAddress = _tokenAddress;
    }

    function getState() public returns(State) {
        if(totalContributions >= ICO_CONTRIBUTION_LIMIT) {
            state = State.COMPLETED;
        }

        return state;
    }

    function pause() public onlyOwner {
        require(!paused, "not unpaused");
        paused = true;
    }

    function unpause() public onlyOwner {
        require(paused, "not paused");
        paused = false;
    }

    function changeState(State newState) public onlyOwner {
        require(state != State.COMPLETED, "ICO completed");
        require(newState != State.COMPLETED, "cant set completed state");
        require(newState > state, "can't move state backwards");
        state = newState;
    }

    function contribute() public payable {
        uint value = msg.value;
        State currentState = getState();
        uint priorContribution = contributions[msg.sender];

        require(!paused, "paused");

        // Hit limit
        require(state != State.COMPLETED, "ICO over");

        // Revert on above contribution max;
        require((totalContributions + value) <= ICO_CONTRIBUTION_LIMIT, "over contribution limit");

        // Check state contribution limits
        if(currentState == State.PRIVATE_SALE) {
            require(whitelisted[msg.sender] == true, "not white listed for private sale");
            require((priorContribution + value) <= PRIVATE_SALE_INDIVIDUAL_LIMIT, "over private sale individual limit");
            require((totalContributions + value) <= PRIVATE_SALE_LIMIT, "over private sale total limit");
        } else if(currentState == State.GENERAL_SALE) {
            require((priorContribution + value) <= GENERAL_SALE_INDIVIDUAL_LIMIT, "over general sale individual limit");
        }

        contributions[msg.sender]+= value;
    }

    function claimTokens() public {
        require(isTokenAddressSet(), "token address not set");
        State currentState = getState();
        require(currentState == State.COMPLETED || currentState == State.OPEN_SALE, "can't claim");
        uint contributionAmount = contributions[msg.sender];
        uint mintAmount = contributionAmount - redeemedETH[msg.sender];
        redeemedETH[msg.sender] += mintAmount;

        SpaceCoin token = SpaceCoin(tokenAddress);
        token.mint(msg.sender, mintAmount * TOKEN_REDEMPTION_MULTIPLIER);
    }
}
