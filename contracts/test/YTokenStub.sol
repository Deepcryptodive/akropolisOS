pragma solidity ^0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Mintable.sol";
import "../interfaces/defi/IYErc20.sol";
import "../common/Base.sol";


contract YTokenStub is IYErc20, Base, ERC20, ERC20Detailed {
    //Stub internals
    uint256 constant EXP_SCALE = 1e18;  //Exponential scale (see Compound Exponential)
    uint256 constant INTEREST_RATE = 10 * EXP_SCALE / 100;  // Annual interest 10%
    uint256 constant INITIAL_RATE = 1 * EXP_SCALE;
    uint256 constant ANNUAL_SECONDS = 365*24*60*60+(24*60*60/4);  // Seconds in a year + 1/4 day to compensate leap years

    ERC20Mintable public underlying;
    uint256 created;



    function initialize(ERC20Mintable _underlying, string uName, uint8 uDecimals) public initializer {
        Base.initialize();
        if(_underlying == address(0)){
            underlying = new ERC20Mintable();
            underlying.initialize();
        }
        ERC20Detailed.initialize(
            string(abi.encodePacked("iearn ", uName)),
            string(abi.encodePacked("y", uName)), 
            uDecimals
        );
        created = now;
    }

    //yToken functions
    function deposit(uint256 amount) external {
        underlying.transferFrom(_msgSender(), address(this), mintAmount);
        uint256 amount = mintAmount.mul(EXP_SCALE).div(_exchangeRate());
        _mint(_msgSender(), amount);
    }
    function withdraw(uint256 shares) external {
        uint256 redeemAmount = redeemTokens.mul(_exchangeRate()).div(EXP_SCALE);
        _burn(_msgSender(), redeemTokens);
        _sendUnderlyuing(_msgSender(), redeemAmount);
    }
    function getPricePerFullShare() external view returns (uint256) {
        return _exchangeRate();
    }

    function _sendUnderlyuing(address recipient, uint256 amount) internal {
        uint256 underlyingBalance = underlying.balanceOf(address(this));
        if (amount > underlyingBalance) {
            underlying.mint(amount - underlyingBalance);
        }
        underlying.transfer(recipient, amount);
    }

    // Stub internals
    function _exchangeRate() internal view returns (uint256) {
        uint256 sec = now.sub(created);
        return INITIAL_RATE.add(INITIAL_RATE.mul(INTEREST_RATE).mul(sec).div(ANNUAL_SECONDS).div(EXP_SCALE));
    }

}