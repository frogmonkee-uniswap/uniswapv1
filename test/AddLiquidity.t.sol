// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AddLiquidty is Test {
    Exchange public exchange;
    IERC20 public token;

    address userA;
    address userB;

    function setUp() public {
        token = new ERC20("frogmonkee", "FROG");
        exchange = new Exchange(address(token));

        userA = makeAddr("User A");
        vm.deal(userA, 2 ether);
        deal(address(token), userA, 10000);

        userB = makeAddr("User B");
        vm.deal(userB, 2 ether);
        deal(address(token), userB, 10000);
    }
    
    function testAddLiquidity() public {
        vm.prank(userA);
        token.approve(address(exchange), 10000);
        vm.prank(userA);
        // xy=k
        // 2*500=1000
        exchange.addLiquidity{ value: 2 ether }(500);
        // Assert balance is 2 ETH
        assertEq(address(exchange).balance, 2e18);
        // Assert 500 tokens are in the exchange contract
        assertEq(exchange.getReserve(), 500);
        // Assert received 2 LP tokens in return
        assertEq(exchange.balanceOf(userA), 2e18);

        vm.prank(userB);
        token.approve(address(exchange), 10000);
        vm.prank(userB);
        exchange.addLiquidity{ value: 2 ether }(300);
        // Assert 250 tokens are added to the exchange, even though 300 were sent
        assertEq(exchange.getReserve(), 750);
        // Assert received 2 LP tokens in return 
        // amountMinted = totalAmount * (ethReserve / ethDeposited​)
        assertEq(exchange.balanceOf(userB), 2e18);
        // Assert exchange balance is 4 ETH
        assertEq(address(exchange).balance, 4e18);
    }
}