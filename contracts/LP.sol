import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "./SpaceCoin.sol";

contract LP is ERC20 {
    uint256 ethBalance;
    uint256 spcBalance;
    uint256 lpBalance;
    SpaceCoin spaceCoin;

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    uint256 k;

    uint256 private unlocked = 1;

    modifier lock() {
        require(unlocked == 1, "UniswapV2: LOCKED");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    constructor(address _spcAddress) ERC20("ETH-SPC LP", "LP") {
        spaceCoin = SpaceCoin(_spcAddress);
    }

    function getSpotPrice() public view returns (uint256) {
        return k / ethBalance;
    }

    function setK() internal {
        ethBalance = address(this).balance;
        spcBalance = spaceCoin.balanceOf(address(this));
        k = ethBalance * spcBalance;
    }

    function getKWithFee() internal view returns (uint256) {
        return (ethBalance - ((ethBalance * 1000) / 3)) * (spcBalance - ((spcBalance * 1000) / 3));
    }

    function swapSPCForETH(address recipient) public lock {
        uint256 swapInAmount = getSPCDelta();
        uint256 temp = getKWithFee() / (swapInAmount + spcBalance);
        uint256 delta = (ethBalance - temp);
        recipient.call{ value: delta }("");
        setK();
    }

    function swapETHForSPC(address recipient) public lock {
        uint256 swapInAmount = getETHDelta();
        uint256 temp = getKWithFee() / (swapInAmount + ethBalance);
        uint256 delta = (spcBalance - temp);
        spaceCoin.transfer(recipient, delta);
        setK();
    }

    function deposit(address sender) public payable lock {
        uint256 ethAmount = getETHDelta();
        uint256 spcAmount = getSPCDelta();

        uint256 liquidity;
        uint256 _totalSupply = totalSupply();
        if (_totalSupply == 0) {
            liquidity = sqrt(ethAmount * spcAmount) - MINIMUM_LIQUIDITY;
        } else {
            liquidity = min((ethAmount * _totalSupply) / ethBalance, (spcAmount * _totalSupply) / spcBalance);
        }

        _mint(sender, liquidity);

        setK();
    }

    function withdraw(address recipient) public lock {
        uint256 lpRemoved = balanceOf(address(this));
        uint256 _totalSupply = totalSupply();
        uint256 percentageOwnership = lpRemoved / _totalSupply;

        uint256 ethRemove = percentageOwnership * ethBalance;
        uint256 spcRemove = percentageOwnership * spcBalance;

        _burn(address(this), lpRemoved);

        recipient.call{ value: ethRemove }("");
        spaceCoin.transfer(recipient, spcRemove);

        setK();
    }

    function getSPCDelta() internal view returns (uint256) {
        return spaceCoin.balanceOf(address(this)) - spcBalance;
    }

    function getETHDelta() internal view returns (uint256) {
        return address(this).balance - ethBalance;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }
}
