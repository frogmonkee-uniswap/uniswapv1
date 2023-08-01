// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AddLiquidty is Test {
    Exchange public exchange;
    IERC20 public token;

    address userA;

    function setUp() public {
        token = new ERC20("frogmonkee", "FROG");
        userA = makeAddr("User A");
        vm.deal(userA, 2 ether);
        deal(address(token), userA, 10000);

        exchange = new Exchange(address(token));
    }
    function testAddLiquidity() public {
        vm.prank(userA);
        token.approve(address(exchange), 1000);
        vm.prank(userA);
        exchange.addLiquidity{ value: 2 ether }(500);
        assertEq(address(exchange).balance, 2e18);
        assertEq(exchange.getReserve(), 500);
    }
}