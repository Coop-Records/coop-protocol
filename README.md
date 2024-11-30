# Wow Factory

The Wow Factory is a factory contract for creating Wow contracts.

## Deployed Contracts (Base Sepolia)

- Wow Implementation: `0x40da74AB965374Ff9a7E07CF88acBFc426Aeac93`
- WowFactoryImpl: `0x7f8d3bf16df0ea2c6eb0d77c9303222313d694a8`
- WowFactory: `0xfd80d1a5d08c2517de22373b28c4d2d619a921b0`

## Usage

1. Deploy the CoopTimedSaleStrategyImpl contract using the following command:

   ```
   forge script script/DeployWowFactory.s.sol:DeployWowFactory --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
   ```

   Replace `RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_API_KEY` with your actual values.

2. Deploy the CoopTimedSaleStrategy contract, passing the address of the CoopTimedSaleStrategyImpl as the `_logic` parameter.
3. For each 1155 token sale, call `setSaleV2()` with the appropriate parameters.
4. Users can mint tokens using the `mint()` function during the sale period.
5. After the sale ends and meets conditions, call `launchMarket()` to enable secondary trading.

## Important Functions

- `deploy()`: Set up a new memecoin.
- `buy()`: Allow users to buy tokens during the sale.
- `sell()`: Allow users to sell tokens during the sale.

For detailed information on function parameters and usage, please refer to the contract documentation.

## Contract Structure

- `WowFactory.sol`: The main implementation contract containing all the logic for the Wow factory.
- `Wow.sol`: A proxy contract that delegates calls to the implementation contract, allowing for upgrades.

For more details on implementation, please refer to the contract source code and comments.
