// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    address public tokenAddress;
    IERC20 public token;

    constructor(address _token) ERC20("uniswapv1", "UNI") {
        require(_token != address(0), "Invalid token address");
        tokenAddress = _token;
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
            uint256 liquidity = totalSupply() * (msg.value / ethReserve);
            _mint(msg.sender, liquidity);
            return liquidity;
        }
    }

    function getBalance(address _minter) public view returns(uint256) {
        return _balances[_minter];
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

    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
        ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
        // Take 1% as fee
        uint256 inputAmountWithFee = inputAmount * 99;
        // Multiply `inputReserve` by 100 since input was multiplied by (100-1)
        return (inputAmountWithFee * outputReserve) / ((inputReserve + inputAmount) * 100);
        }

    function getTokenAmount(uint256 _etherSold) public view returns(uint256) {
        require(_etherSold > 0, "ethSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(_etherSold, address(this).balance, tokenReserve);
    }

    function getEtherAmount(uint256 _tokenSold) public view returns(uint256) {
        require(_tokenSold > 0, "tokenSold is too small");
        uint256 tokenReserve = getReserve();
        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }

    function ethToTokenSwap(uint _minAmount) public payable {
        uint256 tokenReserve = getReserve();
        uint256 tokenBought = getAmount(msg.value, address(this).balance - msg.value, tokenReserve);
        require(tokenBought >= _minAmount, "Insufficient token output amount");
        IERC20(tokenAddress).transfer(address(msg.sender), tokenBought);
    }

    function tokenToEthSwap(uint _tokenSold, uint _minAmount) public {
        uint256 tokenReserve = getReserve();
        uint256 ethBought = getAmount(_tokenSold, tokenReserve, address(this).balance);
        require(ethBought >= _minAmount, "Insufficient eth output amount");
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokenSold);
        payable(msg.sender).transfer(ethBought);        
    }

    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}