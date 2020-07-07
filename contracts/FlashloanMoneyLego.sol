pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

// Import money-legos contracts
import "@studydefi/money-legos/aave/contracts/ILendingPool.sol";
import "@studydefi/money-legos/aave/contracts/IFlashLoanReceiver.sol";
import "@studydefi/money-legos/aave/contracts/FlashloanReceiverBase.sol";
import "@studydefi/money-legos/uniswap/contracts/IUniswapFactory.sol";
import "@studydefi/money-legos/uniswap/contracts/IUniswapExchange.sol";

// Import Openzeppelin contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FlashloanMoneyLego is FlashLoanReceiverBase {
    address public constant AaveLendingPoolAddressProviderAddress = 0x506B0B2CF20FAA8f38a4E2B524EE43e1f4458Cc5;
    address public constant BAT_ADDRESS = 0x2d12186Fbb9f9a8C28B3FfdD4c42920f8539D738;
    address public constant UNISWAP_FACTORY_A = 0xECc6C0542710a0EF07966D7d1B10fA38bbb86523;
    address public constant UNISWAP_FACTORY_B = 0x54Ac34e5cE84C501165674782582ADce2FDdc8F4;

    IUniswapFactory public uniswapFactoryA;
    IUniswapFactory public uniswapFactoryB;
    IUniswapExchange public exchangeAforLoanAsset;
    IUniswapExchange public exchangeBforBAT;

    constructor() public {
      // Override the addressesProvider in the base class to use Kovan for testing
      FlashLoanReceiverBase.addressesProvider = ILendingPoolAddressesProvider(
        AaveLendingPoolAddressProviderAddress
      );

      // Instantiate Uniswap Factory A & B
      uniswapFactoryA = IUniswapFactory(UNISWAP_FACTORY_A);
      uniswapFactoryB = IUniswapFactory(UNISWAP_FACTORY_B);

      // get Exchange B Address
      address exchangeAddressBAT = uniswapFactoryB.getExchange(BAT_ADDRESS);
      // Instantiate Exchange B for BAT Token swaps
      exchangeBforBAT = IUniswapExchange(exchangeAddressBAT);
    }

    function executeOperation(
        address _reserve,
        uint _amount,
        uint _fee,
        bytes calldata _params
    ) external {
        require(_amount <= getBalanceInternal(address(this), _reserve), "Invalid balance, was the flashLoan successful?");

        address RESERVE_ADDRESS = _reserve;
        uint256 deadline = now + 3000;

        // get Exchange Address for the reserve asset
        address exchangeAddressforLoanAsset = uniswapFactoryA.getExchange(RESERVE_ADDRESS);
        // Instantiate Exchange A
        exchangeAforLoanAsset = IUniswapExchange(exchangeAddressforLoanAsset);

        IERC20 loan = IERC20(RESERVE_ADDRESS);
        IERC20 bat = IERC20(BAT_ADDRESS);

        // Swap the reserve asset (e.g. DAI) for BAT
        require(loan.approve(address(exchangeAforLoanAsset), _amount), "Could not approve reserve asset sell");

        uint256 batPurchased = exchangeAforLoanAsset.tokenToTokenSwapInput(
            _amount,
            1,
            1,
            deadline,
            BAT_ADDRESS
        );

        require(bat.approve(address(exchangeBforBAT), batPurchased), "Could not approve BAT asset sell");

        // Swap BAT back to the reserve asset
        uint256 reserveAssetPurchased = exchangeBforBAT.tokenToTokenSwapInput(
            batPurchased,
            1,
            1,
            deadline,
            RESERVE_ADDRESS
        );

        uint totalDebt = _amount.add(_fee);

        require(reserveAssetPurchased > totalDebt, "There is no profit! Reverting!");

        transferFundsBackToPoolInternal(RESERVE_ADDRESS, _amount.add(_fee));
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