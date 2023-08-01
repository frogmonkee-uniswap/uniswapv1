// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Exchange {
    address public tokenAddress;

    constructor(address _token){
        require(_token != address(0), "Invalid token address");
        tokenAddress = _token;
    }

    function addLiquidity(uint256 _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
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

    function getAmount(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
    ) private pure returns (uint256) {
    require(inputReserve > 0 && outputReserve > 0, "invalid reserves");
    return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    function getReserve() public view returns(uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}