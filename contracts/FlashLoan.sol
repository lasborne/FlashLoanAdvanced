// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import 'hardhat/console.sol';
import '@aave/core-v3/contracts/flashloan/base/FlashLoanSimpleReceiverBase.sol';
import '@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './FlashLoanStorage.sol';
import './YieldFarmCompoundV3.sol';

/**
  * @author Lasborne
  * @notice Perform flashloans using Aave V3.
  * @dev The contract is FlashLoanSimpleReceiverBase from Aave to perform flash loans.
  */
contract FlashLoan is FlashLoanSimpleReceiverBase, FlashLoanStorage,
    YieldFarmCompoundV3 {
    using SafeMath for uint256;

    constructor(
      address _flashLoanPool, address _token,
      address _comet, address _cometRewards, address _comp
    )
      FlashLoanSimpleReceiverBase(IPoolAddressesProvider(_flashLoanPool))
      YieldFarmCompoundV3(_comet, _cometRewards, _comp)
    {
      token = IERC20(_token);

      if (msg.sender == address(0xCF7869798aa5132Ef4A245fAE10aC79aB7e62375)) {
        userType = UserType.ADMIN;
      } else {
        userType = UserType.OWNER;
      }
    }

    modifier onlyOwner(){
      require(msg.sender == owner, "Only the owner is allowed to access this function");
      _;
    }

    // ADMIN is the EOA address that uploaded the contract first.
    modifier onlyAdmin() {
      require(userType == UserType.ADMIN, "Function available to only ADMIN");
      _;
    }

    function flashLoanPaybackAmount(uint256 _amount) public pure returns (uint256) {
      uint256 _premium = uint256(_amount.mul(5)).div(10000);
      uint256 _totalAmount = _amount.add(_premium);
      return _totalAmount;
    }

    /**
     * @notice Perform flash loan.
     * @param amount the amount of tokens to be loaned from Aave V3.
     * @dev Calls the FlashLoanSimple function from IPool to take the loan.
     */
    function flashLoan(uint256 amount) external {
        require(msg.sender == owner, "This function can be called by only the owner");
        // Flash Loan data
        address receiverAddress = address(this);
        address asset = address(token);
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;
        uint16 mode = 0; // 0 means no debt swap

        //This is where the flash loan is performed
        POOL.flashLoanSimple(
          receiverAddress,
          asset,
          amounts[0],
          "0x",
          mode
        );
        console.log('Flash Loan obtained');
    }

    /**
     * @notice Input all operations for the flash loan and approve payback.
     * @param asset the address of the borrowed token.
     * @param amount the amount of tokens to be loaned from Aave V3.
     * @param premium the small fee Aave charges for flash loans.
     * @param initiator the address of this contract to do the flash loan.
     * @param params bytes data input into the transaction.
     * @dev Code in the operations of what to do with the borrowed funds.
     * @dev Approve the total= amount + premium for Aave V3 to retrieve its
     * @dev loaned funds and interest all in one transaction, else, transaction
     * @dev rolls back.
     */
    function executeOperation(
      address asset, uint256 amount, uint256 premium,
      address initiator, bytes calldata params
    ) external returns (bool) {
      // Logic for using the Flash loaned amount is put in here.
      lend(asset, amount);
      super.withdrawAll(asset, address(this));
      super.withdrawRewards();

      uint256 balanceOfContract = IERC20(asset).balanceOf(address(this));
      uint256 totalAmount = this.flashLoanPaybackAmount(amount);
      
      require(balanceOfContract >= totalAmount, "Insufficient funds to payback");
      uint256 amountLeft = balanceOfContract.sub(totalAmount);
      // Do something with the funds.


      // Approval of the total amount so that Aave V3 can take back the loan.
      
      IERC20(asset).approve(address(POOL), totalAmount);
      if (amountLeft > 0) {
        IERC20(asset).approve(address(this), amountLeft);
        IERC20(asset).transfer(owner, amountLeft);
      }
      withdrawComp();
      return true;
    }

    /**
     * @notice Withdraw COMP rewards left in this contract address.
     * @dev Withdraw funds, using the transfer function.
     */
    function withdrawComp() internal {
      uint256 compBalance = comp.balanceOf(address(this));
      if (compBalance > 0) {
        comp.approve(address(this), type(uint256).max);
        comp.transfer(owner, compBalance);
      }
    }

    /**
     * @notice Withdraw ERC-20 funds left in this contract address.
     * @dev Withdraw funds, by only the contract's owner, using the balanceOf function.
     */
    function withdrawFunds() external {
      require(msg.sender == owner, "Only the Owner can withdraw funds");
      uint256 balance = token.balanceOf(address(this));
      token.transfer(owner, balance);
    }

    /**
     * @notice Allow this contract to receive native currency i.e. ETHER.
     * @dev Special fall back function in the EVM that tells a contract address
     * @dev to support native currency receiving.
     */
    receive() external payable {
      revert("Sending of ETH not allowed");
    }

}