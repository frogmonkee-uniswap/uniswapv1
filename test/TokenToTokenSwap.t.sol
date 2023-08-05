// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "../src/Factory.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

interface IExchangeTest{
    function addLiquidity(uint256 _tokenAmount) external payable;
    function tokenToTokenSwap(uint256 _tokenSold, uint256 _minAmount, address _tokenAddress) external;
    function balanceOf() external;
}

contract TokentoTokenSwap is Test {    
    Factory public factory;
    address public exchange1Address;
    address public exchange2Address;

    IERC20 public token1;
    IERC20 public token2;

    address LP;
    address swapper;

    function setUp() public {
        // Set up contracts
        factory = new Factory();
        token1 = new ERC20("frogmonkee", "FROG");
        token2 = new ERC20("monkeefrog", "GROF");
        exchange1Address = factory.createNewExchange(address(token1));
        exchange2Address = factory.createNewExchange(address(token2));

        // Set up users
        LP = makeAddr("LP");
        vm.deal(LP, 2 ether);
        deal(address(token1), LP, 1000);
        deal(address(token2), LP, 1000);
        swapper = makeAddr("swapper");
        vm.deal(swapper, 1 ether);
        deal(address(token1), swapper, 1000);

        // LP on exchange1 at 1 ETH & 1000 FROG
        vm.prank(LP);
        token1.approve(address(exchange1Address), 1000);
        vm.prank(LP);
        IExchangeTest(exchange1Address).addLiquidity{ value: 1 ether }(1000);

        // LP on exchange2 at 1 ETH and 1000 GROF
        vm.prank(LP);
        token2.approve(address(exchange2Address), 1000);
        vm.prank(LP);
        IExchangeTest(exchange2Address).addLiquidity{ value: 1 ether }(1000);
    }

    function testTokentoTokenSwap() public {
        assertEq(exchange1Address.balance, 1e18);
        assertEq(token1.balanceOf(exchange1Address), 1000);
        assertEq(exchange2Address.balance, 1e18);
        assertEq(token2.balanceOf(exchange2Address), 1000);

        vm.prank(swapper);
        token1.approve(exchange1Address, 1000);

        vm.prank(swapper);
        IExchangeTest(exchange1Address).tokenToTokenSwap(500, 1, exchange2Address);
        console.log(token1.balanceOf(swapper), "FROG");
        console.log(token2.balanceOf(swapper), "GROF");
    }
}
