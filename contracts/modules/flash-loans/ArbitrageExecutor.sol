pragma solidity ^0.5.0;

// Usage of contracts-ethereum-package here because this contract required
// for ArbitrageModule which is upgradable
import "@openzeppelin/contracts-ethereum-package/contracts/GSN/Context.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-ethereum-package/contracts/math/SafeMath.sol";
import "../../interfaces/flashloans/IFlashLoanReceiver.sol";

//solhint-disable func-order
contract ArbitrageExecutor is Context, IFlashLoanReceiver {
    using SafeMath for uint256;

    uint256 private constant MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    event OperationExecuted(uint256 amount, uint256 fee, uint256 profit);

    address beneficiary;

    modifier onlyBeneficiary() {
        require(_msgSender() == beneficiary, "ArbitrageExecutor: only allowed from beneficiary");
        _;
    }

    constructor(address _beneficiary) public {
        beneficiary = _beneficiary;
    }

    function approve(address[] calldata tokens, address[] calldata exchanges) external onlyBeneficiary {
        for (uint256 i=0; i < tokens.length; i++){
            IERC20 token = IERC20(tokens[i]);
            for (uint256 j=0; j < exchanges.length; j++) {
                token.approve(exchanges[j], MAX_UINT256);
            }
        }
    }

    function withdrawLeftovers(address[] calldata tokens) external onlyBeneficiary {
        for (uint256 i=0; i < tokens.length; i++){
            IERC20 token = IERC20(tokens[i]);
            uint256 balance = token.balanceOf(address(this));
            if (balance > 0){
                token.transfer(beneficiary, balance);
            }
        }
    }

    function executeOperation(address token, uint256 amount, uint256 fee, bytes calldata data) external {
        // Check initial conditions
        uint256 balance = IERC20(token).balanceOf(address(this));
        require(balance == amount, "ArbitrageFlashLoanReceiver: inital amount does not match");

        // Execute operation
        (address contract1, bytes memory message1, address contract2, bytes memory message2) = abi.decode(data, (address, bytes, address, bytes));
        executeExchange(contract1, message1, contract2, message2);

        // Check result and repay + send profit
        balance = IERC20(token).balanceOf(address(this));
        uint256 repay = amount.add(fee);
        require(balance >= repay, "ArbitrageFlashLoanReceiver: not enough funds to return loan");
        IERC20(token).transfer(msg.sender, repay);
        uint256 profit = balance - repay;
        if (profit > 0) {
            IERC20(token).transfer(beneficiary, profit);
        }
        emit OperationExecuted(amount, fee, profit);
    }

    function executeExchange(address contract1, bytes memory message1, address contract2, bytes memory message2) internal {
        bool callSuccess;
        bytes memory result;

        (callSuccess, result) = contract1.call(message1);
        if (!callSuccess) assembly { revert(add(result, 32), result) }

        (callSuccess, result) = contract2.call(message2);
        if (!callSuccess) assembly { revert(add(result, 32), result) }
    }
}