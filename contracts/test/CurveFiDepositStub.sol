pragma solidity ^0.5.12;

import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/ERC20Detailed.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../interfaces/defi/IYErc20.sol";
import "../interfaces/defi/ICurveFiSwap.sol";
import "../interfaces/defi/ICurveFiDeposit.sol";
import "../common/Base.sol";

contract CurveFiDepositStub is Base, ICurveFiDeposit {
    using SafeMath for uint256;

    CurveFiSwapStub public curveFiSwap;

    function initialize(address _curveFiSwap) public initializer {
        Base.initialize();
        curveFiSwap = CurveFiSwapStub(_curveFiSwap);
    }


    function add_liquidity (uint256[3] calldata uamounts, uint256 min_mint_amount) external;
    function remove_liquidity (uint256 _amount, uint256[3] calldata min_uamounts) external;
    function remove_liquidity_imbalance (uint256[3] calldata uamounts, uint256 max_burn_amount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount) external;
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 min_uamount, bool donate_dust) external;
    function withdraw_donated_dust() external;

    function coins(int128 i) external view returns (address);
    function underlying_coins (int128 i) external view returns (address);
    function curve() external view returns (address);
    function token() external view returns (address);
    function calc_withdraw_one_coin (uint256 _token_amount, int128 i) external view returns (uint256);
}