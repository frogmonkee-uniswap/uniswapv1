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
        deal(address(token), swapper, 500);

        // Provide liquidity at 2 ETH & 500 FROG
        vm.prank(LP);
        token.approve(address(exchange), 1000);
        vm.prank(LP);
        exchange.addLiquidity{ value: 1 ether }(1000);
        assertEq(address(exchange).balance, 1e18);
        assertEq(exchange.getReserve(), 1000);
    }

    function testEthSwap() public {
        vm.prank(swapper);
        exchange.ethToTokenSwap{value: 0.33 ether }(240);
        // Check that 245 FROG was received
        assertEq(token.balanceOf(swapper), 500 + 245);
    }

    function testTokenSwap() public {
        vm.prank(swapper);
        token.approve(address(exchange), 1000);
        vm.prank(swapper);
        exchange.tokenToEthSwap(500, 245);
        // Check that 500 FROG was sent
        assertEq(token.balanceOf(swapper), 0);
        // Check that 0.33 ETH was received
        assertEq(swapper.balance, 1e18 + 0.33e18);
    }
}