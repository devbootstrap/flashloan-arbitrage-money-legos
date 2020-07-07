pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

// Import money-legos contracts
import "@studydefi/money-legos/aave/contracts/ILendingPool.sol";
import "@studydefi/money-legos/aave/contracts/IFlashLoanReceiver.sol";
import "@studydefi/money-legos/aave/contracts/FlashloanReceiverBase.sol";

// Import Openzeppelin contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashloanMoneyLego is FlashLoanReceiverBase {
    address constant AaveLendingPoolAddressProviderAddress = 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5;

    constructor() public {
      // Override the addressesProvider in the base class
      FlashLoanReceiverBase.addressesProvider = ILendingPoolAddressesProvider(
        AaveLendingPoolAddressProviderAddress
      );
    }

    function executeOperation(
        address _reserve,
        uint _amount,
        uint _fee,
        bytes calldata _params
    ) external {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        // Function is called when loan is given to contract
        // Do your logic here, e.g. arbitrage, liquidate compound, etc
        // If you don't do any logic then you will need to fund this contract with
        // enough Dai to pay the fee for testing the flashloan logic

        uint totalDebt = _amount.add(_fee);
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    // Entry point for flashloan
    function initateFlashLoan(
        address assetToFlashLoan,
        uint amountToLoan
    ) external {
        bytes memory data = "";

        // Get Aave lending pool
        ILendingPool lendingPool = ILendingPool(addressesProvider.getLendingPool());

        // Ask for a flashloan
        lendingPool.flashLoan(
            address(this),
            assetToFlashLoan,
            amountToLoan,
            data
        );
    }
}