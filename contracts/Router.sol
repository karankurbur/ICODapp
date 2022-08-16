import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./SpaceCoin.sol";
import "./LP.sol";

// To deposit tokens
// 1. Grant allowance to Router
// 2. Call deposit on router, router moves from user -> pool

contract Router {
    SpaceCoin spaceCoin;
    LP lp;

    constructor(address _LPAddress, address _spcAddress) {
        lp = LP(_LPAddress);
        spaceCoin = SpaceCoin(_spcAddress);
    }

    function checkAllowanceSpaceCoin(address sender, uint256 amount) public {
        require(spaceCoin.allowance(sender, address(this)) == amount, "Token is not allowed");
    }

    function checkAllowanceLP(address sender, uint256 amount) public {
        require(lp.allowance(sender, address(this)) == amount, "Token is not allowed");
    }

    // TODO: Helper function to get spcAmount including tax

    function mintLP(uint256 spcAmount, address recipient) public payable {
        uint256 requiredEthAmount = ethNeededForLP(spcAmount);
        require(msg.value == requiredEthAmount);
        checkAllowanceSpaceCoin(msg.sender, spcAmount);

        // TODO: Factor in tax when calculating

        // Send funds into LP contract
        spaceCoin.transferFrom(msg.sender, address(lp), spcAmount);

        // Deposit will give LP tokens to recipient
        // If called from ICO contract, it will be given to the caller of claimAndLP
        // If called from EOA, caller will set the recipient to their address
        lp.deposit{ value: msg.value }(recipient);
    }

    function burnLP(uint256 lpAmount) public {
        checkAllowanceLP(msg.sender, lpAmount);

        // Send funds into LP contract
        lp.transferFrom(msg.sender, address(lp), lpAmount);

        lp.withdraw(msg.sender);
    }

    function isSPCTaxEnabled() internal returns (bool) {
        return spaceCoin.taxEnabled();
    }

    function ethNeededForLP(uint256 spcAmount) public returns (uint256) {
        uint256 spotPrice = lp.getSpotPrice();
        if (isSPCTaxEnabled()) {
            // We need ETH to match SPC after 2% tax
            return (spcAmount * spotPrice * 98) / 100;
        } else {
            return spcAmount * spotPrice;
        }
    }

    // TODO: Trades -> slippage etc

    function trade() public payable {}

    function getSpotPrice() public returns (uint256) {
        return lp.getSpotPrice();
    }
}
