// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './CometInterface.sol';
import 'hardhat/console.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IERC20NonStandard.sol';
import './CometRewards.sol';
import './FlashLoanStorage.sol';


/**
  * @author Lasborne
  * @notice Use FlashLoaned fund to farm yield in COMPOUND by supplying and borrowing.
  * @dev The contract is YieldFarm to farm COMP tokens using flash loan from Aave.
  */
contract YieldFarmCompoundV3 is FlashLoanStorage{
    using SafeMath for uint256;

    constructor(
      address _comet, address _cometRewards, address _comp
    ) FlashLoanStorage(_comet, _cometRewards, _comp) {}

    /**
     * @notice Gets the amount of approved tokens to be spent by addresses.
     * @dev Get to allowance function of the ERC20 contract.
     * @dev Returns allowance in uint256.
     */
    function getAllowance(
      address _owner, address _sender, address _token
    ) public view returns (uint256) {
      return IERC20(_token).allowance(_owner, _sender);
    }

    /**
     * @notice Gets the balance of tokens owned by the 'original EOA' address.
     * @param _token The ERC20 token to get balance from.
     * @dev Returns balance of the sender of the transaction.
     */
    function getBalance(address _token) public view returns (uint256) {
      return IERC20(_token).balanceOf(tx.origin);
    }

    /**
     * @notice Gets the COMP balance of tokens owned by the Contract address.
     * @dev Returns balance of the sender of the transaction.
     */
    function getCompBalance() public view returns (uint256 compBalance) {
      compBalance = comp.balanceOf(address(this));
      return compBalance;
    }

    /**
     * @notice Approves an amount for the cometProxy to spend owner tokens.
     * @param _amount the amount to be approved.
     * @param _token the ERC20 token to be approved for spending.
     * @dev Returns original approval result.
     */
    function doApproval(address _token, uint256 _amount) public returns (
    bool) {
      require (getBalance(_token) >= _amount, "Insufficient balance!");
      (bool success, bytes memory data) = _token.delegatecall(
        abi.encodeWithSignature(
          "approve(address, uint256)", address(comet),
          _amount
        )
      );
      if (success) {
        return abi.decode(data, (bool));
      } else {
        return false;
      }
    }

    /**
     * @notice Transfers an amount from the owner to this contract address.
     * @param _amount the amount to be transferred.
     * @dev First checks the allowance is atleast equal to the amount for transfer.
     * @dev Proxy uses a call to get transferFrom function of the implementation contract.
     * @dev Returns original result in bool if call is successful.
     */
    function doTransfer(
      address _token, uint256 _amount, address _owner, address _sender 
    ) public {
      //doApproval(_token, _amount);
      require (
        getAllowance(_owner, _sender, _token) >= _amount, 
        "Inadequate amount approved!"
      );
      IERC20(_token).transferFrom(_owner, _sender, _amount);
    }
    
    /**
     * @notice Function not yet in use.
     * @notice lend Flash loaned amount to Compound finance.
     * @param _amount the amount of tokens supplied.
     * @param _token the address of the lent token.
     * @dev Approves the comet address to spend flashloaned fund.
     * @dev Calls the comet's supply function.
     */
    function lend(address _token, uint _amount) internal {
      // approval for the Comet contract to spend tokens
      IERC20(_token).approve(address(comet), _amount);
      // Supply funds
      comet.supply(_token, _amount);
      dueAmount[address(this)] = _amount;
      emit LendToComp(address(owner), address(this), _amount);
    }

    /**
     * @notice This function is not use yet.
     * @notice withdraw invested Flash loan funds and rewards given.
     * @param _token the token to be withdrawn from Comet.
     * @param _sender the sender of the transaction.
     * @dev Checks balance of this contract and withdraws all funds.
     * @dev Redeems rewards and funds from cTokens to regular tokens.
     */
    function withdrawAll(address _token, address _sender) internal {
      IERC20NonStandard(address(comet)).approve(
        address(comet), type(uint256).max
      );
      comet.withdraw(_token, type(uint256).max);
      withdrawnAmount[_sender] = comet.balanceOf(_sender);
    }

    /**
     * @notice This function is not in use yet.
     * @notice withdraw rewards given.
     * @dev Checks balance of this contract and withdraws COMP.
     * @dev Transfers Comp rewards to msg.sender
     */
    function withdrawRewards() internal {
      cometRewards.claim(address(comet), address(this), true);
    }

    /**
     * @notice This function is not in use yet.
     * @notice borrow funds.
     * @dev Approves the cToken address for borrowing.
     * @dev Create an array containing cToken address.
     * @dev Enter the borrow market.
     */
    function borrow(uint256 _amount) external{
      uint256 _borrowAmount = (_amount.div(2));

      //loanedToken.approve(address(cBorrowedToken), borrowAmount);

      // Signals to compound that a token lent will be used as a collateral.

      // Borrow 50% of the same collateral provided.
      
      comet.withdraw(address(comet), _borrowAmount);
    }

    /**
     * @notice This function is not in use yet.
     * @notice pay back borrowed funds.
     * @dev Approve the cToken address for repay with a higher amount.
     * @dev Repay borrowed amount and reset.
     * @dev Enter the borrow market.
     */
    function payback() external returns (bool) {
      //borrowedToken.approve(address(Comet), (type(uint256).max));
      (bool success3, bytes memory result3) = address(
        comet
      ).delegatecall(abi.encodeWithSignature(
        "approve(address, uint256)", address(comet), type(uint256).max
      ));
      if (success3) {
        comet.supply(
          address(comet), comet.borrowBalanceOf(address(this))
        );
        return abi.decode(result3, (bool));
      } else {
        return false;
      }
      // Reset borrow amount back to 0 after pay out is executed.
      
    }
}