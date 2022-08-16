import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
pragma solidity >=0.8.0 <0.9.0;

contract SpaceCoin is ERC20 {

    address public treasury;
    address public owner;
    address public ico;
    uint public maxSupply = 500000 * 1e18;
    bool public taxEnabled = false;

    constructor(address treasuryAddress, address icoAddress) ERC20("Space Coin", "SPC") {
        treasury = treasuryAddress;
        ico = icoAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function enableTax() public onlyOwner {
        require(taxEnabled == false, "tax is disabled");
        taxEnabled = true;
    }

    function disableTax() public onlyOwner {
        require(taxEnabled == true, "tax needs to be enabled");
        taxEnabled = false;
    }

    function mint(address account, uint amount) public {
        require(msg.sender == ico, "not ico contract");
        (uint sendAmount, uint taxAmount) = calculateTax(amount);

        // We can mint the tax to the treasury address.
        if(taxAmount > 0) {
            _mint(treasury, taxAmount);
        }
        _mint(account, sendAmount);
        require(totalSupply() <= maxSupply, "over max supply");
    }

    function calculateTax(uint amount) internal view returns (uint, uint) {
        uint sendAmount;
        uint taxAmount;

        if(!taxEnabled) {
            sendAmount = amount;
        } else {
            taxAmount = amount * 2 / 100;
            sendAmount = amount - taxAmount;
        }
        return (sendAmount, taxAmount);
    }

    function treasuryTransfer(uint amount) internal returns (bool) {
        return super.transfer(treasury, amount);
    }

    function transfer(address recipient, uint amount) public virtual override returns (bool) {
        (uint sendAmount, uint taxAmount) = calculateTax(amount);
        if(taxAmount > 0) {
            require(treasuryTransfer(taxAmount), "treasury transfer failed");
        }
        return super.transfer(recipient, sendAmount);
    }
}
