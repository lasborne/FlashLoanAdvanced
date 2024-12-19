// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import './CometInterface.sol';
import './CometRewards.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

abstract contract FlashLoanStorage {

    error TransferError();
    error WithdrawalError();

    event LendToComp(address indexed from, address indexed to, uint256 amount);
    event FlashLoan(address indexed taker, uint256 amount, uint40 timeTaken);
    event WithdrawFromComp(address indexed from, address indexed to, uint256 amount);
    event WithdrawCompRewards(address indexed comp, uint256 amount);

    IERC20 public token;
    IERC20 immutable comp;
    CometInterface immutable comet;
    CometRewards immutable cometRewards;
    address immutable owner;
    UserType internal userType;
    address constant admin = address(0xCF7869798aa5132Ef4A245fAE10aC79aB7e62375);

    mapping(address => uint256) internal balance;
    mapping(address => uint256) internal borrowAmount;
    mapping(address => uint256) internal withdrawnAmount;
    mapping(address => uint256) internal dueAmount;
    mapping(address => mapping(address => uint256)) internal _allowance;
    
    enum UserType{
      USER,
      OWNER,
      ADMIN
    }
    constructor(address _comet, address _cometRewards, address _comp) {
        owner = msg.sender;
        comet = CometInterface(_comet);
        cometRewards = CometRewards(_cometRewards);
        comp = IERC20(_comp);
    }
    
}