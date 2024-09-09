// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "@aave/protocol-v2/contracts/flashloan/interfaces/IFlashLoanReceiver.sol";
import "@aave/protocol-v2/contracts/dependencies/openzeppelin/contracts/Ownable.sol";

contract AaveFlashLoan is IFlashLoanReceiver, Ownable {
    ILendingPoolAddressesProvider public provider;
    ILendingPool public lendingPool;
    address public weth;

    // Declare arrays for flash loan parameters
    address[] public loanAssets;
    uint256[] public loanAmounts;
    uint256[] public loanModes;

    constructor(address _provider, address _weth) public {
        provider = ILendingPoolAddressesProvider(_provider);
        lendingPool = ILendingPool(provider.getLendingPool());
        weth = _weth;

        // Initialize arrays with size 1
        // loanAssets = new address ;
        // loanAmounts = new uint256 ;
        // loanModes = new uint256 ;
    }

    function executeFlashLoan(uint256 amount) external onlyOwner {
        loanAssets[0] = weth;
        loanAmounts[0] = amount;
        loanModes[0] = 0; // 0 = no debt, 1 = stable, 2 = variable

        bytes memory params = "";
        uint16 referralCode = 0;

        lendingPool.flashLoan(
            address(this),
            loanAssets,
            loanAmounts,
            loanModes,
            address(this),
            params,
            referralCode
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premium,
        // address initiator,
        bytes calldata params
    ) external  returns (bool) {
        require(assets[0] == weth, "Not WETH");

        uint256 amountOwed = amounts[0] + premium[0];

        // Your logic goes here: arbitrage, collateral swap, liquidation, etc.

        // Approve the LendingPool contract to pull the owed amount (loan + fee)
        IERC20(assets[0]).approve(address(lendingPool), amountOwed);

        return true;
    }

    function withdraw() external onlyOwner {
        uint256 balance = IERC20(weth).balanceOf(address(this));
        require(balance > 0, "No WETH balance to withdraw");
        IERC20(weth).transfer(msg.sender, balance);
    }

    receive() external payable {}

    // Implement the required interface methods
    function ADDRESSES_PROVIDER() external view override returns (ILendingPoolAddressesProvider) {
        return provider;
    }

    function LENDING_POOL() external view override returns (ILendingPool) {
        return lendingPool;
    }
}
