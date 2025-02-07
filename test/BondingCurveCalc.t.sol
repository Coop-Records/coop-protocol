// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {BondingCurve} from "../src/BondingCurve.sol";

contract BondingCurveCalcTest is Test {
    BondingCurve public bondingCurve;
    uint256 public constant PRIMARY_MARKET_SUPPLY = 600_000_000e18; // Changed to 600M tokens

    function setUp() public {
        bondingCurve = new BondingCurve();
    }

    function testCalculateGraduationCost() public {
        // Calculate ETH needed to buy PRIMARY_MARKET_SUPPLY tokens starting from 0 supply
        uint256 ethRequired = bondingCurve.getTokenBuyQuote(0, PRIMARY_MARKET_SUPPLY);
        
        // Convert to human readable ETH amount
        uint256 ethInWhole = ethRequired / 1e18;
        uint256 ethDecimal = (ethRequired % 1e18) / 1e16; // Get 2 decimal places

        console.log("ETH required to graduate market:");
        console.log("Raw Wei:", ethRequired);
        console.log("In ETH: %s.%s ETH", ethInWhole, ethDecimal);
    }

    function testBuyInChunks() public {
        uint256 chunkSize = PRIMARY_MARKET_SUPPLY / 4; // Test buying in 4 chunks
        uint256 currentSupply = 0;
        uint256 totalEthRequired = 0;

        for(uint256 i = 0; i < 4; i++) {
            uint256 ethForChunk = bondingCurve.getTokenBuyQuote(currentSupply, chunkSize);
            totalEthRequired += ethForChunk;
            currentSupply += chunkSize;
            
            console.log("Chunk %s cost: %s ETH", i + 1, ethForChunk / 1e18);
        }

        console.log("Total ETH required (buying in chunks): %s ETH", totalEthRequired / 1e18);
    }

    function testFirstTokenPrice() public {
        // Test buying just 1e18 tokens (1 full token) at the start
        uint256 ethRequired = bondingCurve.getTokenBuyQuote(0, 1e18);
        console.log("Cost of first token (in wei):", ethRequired);
        console.log("Cost of first token (in ETH): %s ETH", ethRequired / 1e18);
    }

    function testLastTokenPrice() public {
        // Test buying the final 1e18 tokens right before graduation
        uint256 ethRequired = bondingCurve.getTokenBuyQuote(PRIMARY_MARKET_SUPPLY - 1e18, 1e18);
        console.log("Cost of last token (in wei):", ethRequired);
        console.log("Cost of last token (in ETH): %s ETH", ethRequired / 1e18);
    }
} 