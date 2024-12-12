// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {Coop} from "../src/Coop.sol";
import {BondingCurve} from "../src/BondingCurve.sol";
import {IWETH} from "../src/interfaces/IWETH.sol";
import {ICoop} from "../src/interfaces/ICoop.sol";
import {CoopFactory} from "../src/CoopFactory.sol";
import {CoopFactoryImpl} from "../src/CoopFactoryImpl.sol";
import {INonfungiblePositionManager} from "../src/interfaces/INonfungiblePositionManager.sol";

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

    function test_InitialState() public {
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
}
