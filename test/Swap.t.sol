// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Exchange.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract AddLiquidty is Test {
    Exchange public exchange;
    IERC20 public token;

    address LP;
    address swapper;

    function setUp() public {
        // Set up token and exchange contracts
        token = new ERC20("frogmonkee", "FROG");
        exchange = new Exchange(address(token));

        // Instatiate users with ETH and FROG balances
        LP = makeAddr("LP");
        vm.deal(LP, 2 ether);
        deal(address(token), LP, 10000);
        swapper = makeAddr("swapper");
        vm.deal(swapper, 1 ether);
        deal(address(token), swapper, 250);

        // Provide liquidity at 2 ETH & 500 FROG
        vm.prank(LP);
        token.approve(address(exchange), 1000);
        vm.prank(LP);
        exchange.addLiquidity{ value: 2 ether }(500);
        assertEq(address(exchange).balance, 2e18);
        assertEq(exchange.getReserve(), 500);
    }

    function testEthSwap() public {
        vm.prank(swapper);
        exchange.ethToTokenSwap{value: 1 ether }(164);
        // Check that 1 eth was sent
        assertEq(swapper.balance, 0);
        // Check that 246 FROG was received
        assertEq(token.balanceOf(swapper), 250 + 165);
    }

    function testTokenSwap() public {
        vm.prank(swapper);
        token.approve(address(exchange), 1000);
        vm.prank(swapper);
        exchange.tokenToEthSwap(250, 249);
        // Check that 250 FROG was sent
        assertEq(token.balanceOf(swapper), 0);
        // Check that 0.66 ETH was received
        assertEq(swapper.balance, 1e18 + 0.66e18);
    }
}