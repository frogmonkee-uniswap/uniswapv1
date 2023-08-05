// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "./Factory.sol";

interface IFactory {
  function getExchange(address _tokenAddress) external returns (address);
}

interface IExchange {
    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
    function ethToTokenSwap(uint256 _minTokens) external payable;
    }

contract Exchange is ERC20 {
    address public factoryAddress;
    address public tokenAddress;
    IERC20 public token;

    constructor(address _token) ERC20("uniswapv1", "UNI") {
        require(_token != address(0), "Invalid token address");
        tokenAddress = _token;
        factoryAddress = msg.sender;
        token = IERC20(tokenAddress);
    }

    function addLiquidity(uint256 _tokenAmount) public payable returns(uint256) {
        // If pool has not been initialized, then accept tokens + ETH
        if(getReserve() == 0) {
            // Transfer tokens from user's wallet to Exchange contract
            token.transferFrom(msg.sender, address(this), _tokenAmount);
            // mint LP tokens proportioal to ETH deposited
            uint256 liquidity = address(this).balance;
            _mint(msg.sender, liquidity);
            return liquidity;
        } else {
            // If pool exist, it must follow price curve. Enforce price of token based on msg.value
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getReserve();
            uint256 tokenAmount = (msg.value * tokenReserve) / address(this).balance;
            require(_tokenAmount >= tokenAmount, "Deposit more tokens");
            // Transfers exact tokenAmount and leaves _tokenAmount - tokenAmount in the user's wallet
            token.transferFrom(msg.sender, address(this), tokenAmount);
            // amountMinted = totalAmount * (ethReserve / ethDeposited​)
            uint256 liquidity = (totalSupply() * msg.value ) / ethReserve;
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function removeLiquidity(uint256 _amount) public returns(uint256, uint256) {
        require(_amount > 0, "invalid amount");
        // EthAmount = (ethReserve * amountLP) / totalAmountLP​
        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        // EthAmount = (tokenReserve * amountLP) / totalAmountLP​
        uint256 tokenAmount = (getReserve() * _amount) / totalSupply();
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        token.transfer(msg.sender, tokenAmount);
        return (ethAmount, tokenAmount);
    }

    function ethToToken(uint _minAmount, address recipient) private {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokenBought >= _minAmount, "Insufficient token output amount");
        IERC20(tokenAddress).transfer(recipient, tokenBought);
    }

    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToEthSwap(uint _tokenSold, uint _minAmount) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        require(ethBought >= _minAmount, "Insufficient eth output amount");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);        
    }

    function tokenToTokenSwap(uint256 _tokenSold, uint256 _minAmount, address _tokenAddress) public {
        address exchangeAddress = _tokenAddress;
        /* I had to change the following line into the above for TokenToTokenSwap.t.sol. 
           I was getting a revert error calling getExchange, so I just used the test contract pass through `exchange2Address`
           Instead of using the factory interface call `getExchange`
        */ 
//        address exchangeAddress = IFactory(tokenAddress).getExchange(_tokenAddress);
        require(exchangeAddress != address(this) && exchangeAddress != address(0), "Invalid exchange address");
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        IExchange(exchangeAddress).ethToTokenTransfer{value: ethBought}(_minAmount, msg.sender);
    }

    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getBalance(address _minter) public view returns(uint256) {
        return _balances[_minter];
    }

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
        ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        // Take 1% of input token as fee
        uint256 inputAmountWithFee = inputAmount * 99;
        // Multiply `inputReserve` by 100 since input was multiplied by (100-1)
        return (inputAmountWithFee * outputReserve) / ((inputReserve + inputAmount) * 100);
    }
}