// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {Coop} from "../src/Coop.sol";
import {BondingCurve} from "../src/BondingCurve.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ICoop} from "../src/interfaces/ICoop.sol";
import {CoopFactory} from "../src/CoopFactory.sol";
import {CoopFactoryImpl} from "../src/CoopFactoryImpl.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";
import {IProtocolRewards} from "../src/interfaces/IProtocolRewards.sol";

contract CoopTest is Test {
    Coop public coopImpl;
    Coop public coop;
    BondingCurve public bondingCurve;
    CoopFactory public factory;
    CoopFactoryImpl public factoryImpl;

    address public constant WETH = 0x4200000000000000000000000000000000000006;
    address public constant PROTOCOL_FEE_RECIPIENT = address(0x1111);
    address public constant PROTOCOL_REWARDS = address(0x2222);
    address public constant NFT_POSITION_MANAGER = address(0x3333);
    address public constant SWAP_ROUTER = address(0x4444);
    address public constant TOKEN_CREATOR = address(0x5555);
    address public constant PLATFORM_REFERRER = address(0x6666);
    address public constant MOCK_POOL = address(0x7777);

    function setUp() public {
        // Deploy bonding curve
        bondingCurve = new BondingCurve();

        // Deploy Coop implementation
        coopImpl = new Coop(
            PROTOCOL_FEE_RECIPIENT,
            PROTOCOL_REWARDS,
            WETH,
            NFT_POSITION_MANAGER,
            SWAP_ROUTER
        );

        // Deploy factory implementation
        factoryImpl = new CoopFactoryImpl(
            address(coopImpl),
            address(bondingCurve)
        );

        // Initialize factory implementation
        bytes memory initData = abi.encodeWithSelector(
            CoopFactoryImpl.initialize.selector,
            address(this) // owner
        );

        // Deploy factory
        factory = new CoopFactory(address(factoryImpl), initData);

        // Setup mock NFT Position Manager behavior
        vm.mockCall(
            NFT_POSITION_MANAGER,
            abi.encodeWithSelector(
                INonfungiblePositionManager
                    .createAndInitializePoolIfNecessary
                    .selector
            ),
            abi.encode(MOCK_POOL)
        );

        // Setup mock WETH behavior
        vm.mockCall(
            WETH,
            abi.encodeWithSelector(IWETH.deposit.selector),
            abi.encode()
        );

        vm.mockCall(
            WETH,
            abi.encodeWithSelector(IWETH.approve.selector),
            abi.encode(true)
        );

        // Setup mock Protocol Rewards behavior
        vm.mockCall(
            PROTOCOL_REWARDS,
            abi.encodeWithSelector(IProtocolRewards.depositBatch.selector),
            abi.encode()
        );

        // Deploy Coop token through factory
        address coopAddress = CoopFactoryImpl(address(factory)).deploy(
            TOKEN_CREATOR,
            PLATFORM_REFERRER,
            "test-uri",
            "TEST",
            "TST"
        );

        coop = Coop(payable(coopAddress));
    }

    function test_InitialState() public view {
        assertEq(
            uint256(coop.marketType()),
            uint256(ICoop.MarketType.BONDING_CURVE)
        );
        assertEq(coop.tokenCreator(), TOKEN_CREATOR);
        assertEq(coop.platformReferrer(), PLATFORM_REFERRER);
        assertEq(address(coop.bondingCurve()), address(bondingCurve));
        assertEq(coop.name(), "TEST");
        assertEq(coop.symbol(), "TST");
    }

    function test_RevertOnTooSmallAmount() public {
        uint256 tooSmall = coop.MIN_ORDER_SIZE() - 1;
        vm.deal(address(this), tooSmall);

        vm.expectRevert(ICoop.EthAmountTooSmall.selector);
        coop.buy{value: tooSmall}(
            address(this),
            address(this),
            address(0),
            "",
            ICoop.MarketType.BONDING_CURVE,
            0,
            0
        );
    }

    function test_TokenBuyQuote() public view {
        // Test with zero current supply
        uint256 quote1 = coop.getTokenBuyQuote(1 ether);
        assertGt(quote1, 0, "Quote should be positive");

        // Test with some existing supply
        uint256 buyAmount = 100 ether;
        uint256 quote2 = coop.getTokenBuyQuote(buyAmount);
        assertGt(quote2, 0, "Quote should be positive");

        // Test that buying more tokens costs more ETH
        uint256 smallerBuyAmount = 50 ether;
        uint256 quote3 = coop.getTokenBuyQuote(smallerBuyAmount);
        assertGt(quote2, quote3, "Buying more tokens should cost more ETH");

        // Test precision - very small amount
        uint256 tinyAmount = 0.000001 ether;
        uint256 quote4 = coop.getTokenBuyQuote(tinyAmount);
        assertGt(quote4, 0, "Should handle tiny amounts");

        // Test precision - very large amount
        uint256 largeAmount = 1_000_000 ether;
        uint256 quote5 = coop.getTokenBuyQuote(largeAmount);
        assertGt(quote5, quote2, "Large amounts should cost more");
    }

    function test_EthBuyQuote() public view {
        // Test with zero current supply
        uint256 quote1 = coop.getEthBuyQuote(1 ether);
        assertGt(quote1, 0, "Quote should be positive");

        // Test with larger ETH amount
        uint256 quote2 = coop.getEthBuyQuote(10 ether);
        assertGt(quote2, quote1, "More ETH should get more tokens");

        // Test precision - very small amount
        uint256 quote3 = coop.getEthBuyQuote(0.000001 ether);
        assertGt(quote3, 0, "Should handle tiny amounts");

        // Test precision - very large amount
        uint256 quote4 = coop.getEthBuyQuote(1000 ether);
        assertGt(quote4, quote2, "More ETH should get more tokens");
    }

    function test_Calculate21PercentSupply() public view {
        // Calculate 21% of 1 billion (graduated supply)
        uint256 totalSupply = 1_000_000_000 * 1e18; // 1 billion with 18 decimals
        uint256 targetAmount = (totalSupply * 21) / 100; // 21% of total supply

        // Get ETH quote for this amount of tokens from bonding curve
        uint256 baseEthNeeded = bondingCurve.getTokenBuyQuote(0, targetAmount);

        // Add 2% buffer for fees and slippage
        uint256 ethWithBuffer = (baseEthNeeded * 102) / 100;

        console.log(
            "Base ETH needed for 21% of graduated supply (%s tokens): %s ETH",
            targetAmount / 1e18,
            baseEthNeeded / 1e18
        );

        console.log(
            "Total ETH needed with 2% buffer: %s ETH",
            ethWithBuffer / 1e18
        );

        // Also show in Wei for precision
        console.log("Base ETH needed (in Wei): %s", baseEthNeeded);
        console.log("Total ETH needed with buffer (in Wei): %s", ethWithBuffer);
    }

    function test_InitialMint21Percent() public {
        // Calculate 21% of graduated supply (1B tokens)
        uint256 graduatedSupply = 1_000_000_000 * 1e18; // 1B tokens
        uint256 approximateTarget = (graduatedSupply * 21) / 100; // 21% of total supply

        // Get ETH quote for this amount of tokens
        uint256 baseEthNeeded = bondingCurve.getTokenBuyQuote(
            0,
            approximateTarget
        );

        // Add 2% extra ETH to account for fees
        uint256 ethNeeded = (baseEthNeeded * 102) / 100;

        // Calculate exact tokens we'll receive for this ETH amount
        uint256 ethAfterFees = (ethNeeded * 99) / 100; // Remove 1% fee
        uint256 exactTokenAmount = bondingCurve.getEthBuyQuote(0, ethAfterFees);

        console.log(
            "Approximate target (21%%): %s tokens",
            approximateTarget / 1e18
        );
        console.log(
            "Exact tokens we'll receive: %s tokens",
            exactTokenAmount / 1e18
        );
        console.log(
            "Difference: %s tokens (%s%%)",
            (exactTokenAmount - approximateTarget) / 1e18,
            ((exactTokenAmount - approximateTarget) * 100) / approximateTarget
        );
        console.log("ETH needed (in Wei): %s", ethNeeded);

        // Now let's simulate creating a token and buying tokens in the same tx
        vm.deal(address(this), ethNeeded);

        // Use a different block number and timestamp to ensure unique salt
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 1);

        // Deploy new token with unique parameters
        address coopAddress = CoopFactoryImpl(address(factory)).deploy(
            TOKEN_CREATOR,
            PLATFORM_REFERRER,
            string(abi.encodePacked("test-uri-", block.timestamp)),
            "MUSIC",
            "MSC"
        );

        require(coopAddress != address(0), "Deployment failed");
        Coop newCoop = Coop(payable(coopAddress));

        // Buy tokens with 0% slippage - must receive exact amount
        uint256 receivedAmount = newCoop.buy{value: ethNeeded}(
            address(this),
            address(this),
            address(0),
            "",
            ICoop.MarketType.BONDING_CURVE,
            exactTokenAmount, // Require exact amount we calculated - no slippage
            0
        );

        // Verify we got exactly what the buy function returned
        uint256 balance = newCoop.balanceOf(address(this));
        assertEq(
            balance,
            receivedAmount,
            "Should have received amount returned by buy function"
        );

        // Log the actual amount received
        console.log("Actually received %s tokens", balance / 1e18);
    }

    function test_SmallPurchase() public {
        // Try to buy 1% of primary supply
        uint256 primarySupply = 800_000_000 ether; // 800M tokens
        uint256 targetAmount = primarySupply / 100; // 1% of primary supply

        // Get ETH quote for this amount of tokens
        uint256 baseEthNeeded = bondingCurve.getTokenBuyQuote(0, targetAmount);

        // Add 2% extra ETH to account for fees and slippage
        uint256 ethNeeded = (baseEthNeeded * 102) / 100;

        console.log(
            "ETH needed for 1% of primary supply (%s tokens): %s ETH (including extra for fees)",
            targetAmount / 1 ether,
            ethNeeded / 1 ether
        );

        // Now let's simulate creating a token and buying 1% in the same tx
        vm.deal(address(this), ethNeeded);

        // Deploy new token with unique parameters
        address coopAddress = CoopFactoryImpl(address(factory)).deploy(
            TOKEN_CREATOR,
            PLATFORM_REFERRER,
            "test-uri-small",
            "MUSIC",
            "MSC"
        );

        require(coopAddress != address(0), "Deployment failed");
        Coop newCoop = Coop(payable(coopAddress));

        // Buy tokens
        newCoop.buy{value: ethNeeded}(
            address(this),
            address(this),
            address(0),
            "",
            ICoop.MarketType.BONDING_CURVE,
            (targetAmount * 95) / 100, // Allow for 5% slippage
            0
        );

        // Verify we got at least 95% of the target amount (accounting for fees)
        uint256 balance = newCoop.balanceOf(address(this));
        assertGe(
            balance,
            (targetAmount * 95) / 100,
            "Should have received at least 95% of target amount"
        );

        // Log the actual amount received
        console.log(
            "Actually received %s tokens (%s%% of target)",
            balance / 1 ether,
            (balance * 100) / targetAmount
        );
    }
}
