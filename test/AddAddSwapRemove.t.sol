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
    address swapper;

    function setUp() public {
        token = new ERC20("frogmonkee", "FROG");
        exchange = new Exchange(address(token));

        userA = makeAddr("User A");
        vm.deal(userA, 2 ether);
        deal(address(token), userA, 10000);
        userB = makeAddr("User B");
        vm.deal(userB, 2 ether);
        deal(address(token), userB, 10000);
        swapper = makeAddr("Swapper");
        vm.deal(swapper, 2 ether);
    }
        // Testing pool actions with 2 LPs providing 1/3 & 2/3s of liquidity 
        function testAddAddSwapRemoveLiquidity() public {
        vm.prank(userA);
        token.approve(address(exchange), 10000);
        vm.prank(userA);
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
        exchange.addLiquidity{ value: 1 ether }(250);
        // Assert balance is 4 ETH
        assertEq(address(exchange).balance, 3e18);
        // Assert 500 tokens are in the exchange contract
        assertEq(exchange.getReserve(), 666);
        // Assert received 2 LP tokens in return
        assertEq(exchange.balanceOf(userB), 1e18);

        // Swap
        vm.prank(swapper);
        exchange.ethToTokenSwap{value: 1 ether }(147);
        // Check that 1 eth was sent
        assertEq(swapper.balance, 1e18);
        // Check that 164 FROG was received
        assertEq(token.balanceOf(swapper), 164);
        
        // Remove liquidity
        vm.prank(userA);
        exchange.removeLiquidity(2e18);
        // Assert userA has 2.5 ETH after removal
        assertEq(userA.balance, 2666666666666666666);
        // Assert userA has 9500 + 334 $FROG after removal
        assertEq(token.balanceOf(userA), 9834);
    }
}