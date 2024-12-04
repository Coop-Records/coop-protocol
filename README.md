# Coop Factory

The Coop Factory is a factory contract for creating Coop contracts.

## Deployments

### Base Sepolia

- Coop Implementation: `0x601144c73826edf12b02f8683d70626819d3dbaf`
- CoopFactoryImpl: `0x68068f759a262212adf1df16ab536043ec95ace9`
- CoopFactory Proxy: `0xa6265db7f16868c8d911dd5db51bd0924db0362e`

## Deployed Contracts (Base Sepolia)

- Wow Implementation: `0xbf0f3d5a13d193e79f5c4154dbe4b4738797aa45`
- WowFactoryImpl: `0x4d8963a851533abeef38425468fec7fe1a53a169`
- WowFactory: `0x490f4945061b43dd0e38ee503a077d0bffd94737`

## Usage

1. Deploy the Coop implementation contract using the following command:

   ```
   forge script script/DeployCoopFactory.s.sol:DeployCoopFactory --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify --etherscan-api-key $ETHERSCAN_API_KEY -vvvv
   ```

   Replace `RPC_URL`, `PRIVATE_KEY`, and `ETHERSCAN_API_KEY` with your actual values.

2. Deploy the Coop contract, passing the address of the CoopFactoryImpl as the `_logic` parameter.
3. For each 1155 token sale, call `setSaleV2()` with the appropriate parameters.
4. Users can mint tokens using the `mint()` function during the sale period.
5. After the sale ends and meets conditions, call `launchMarket()` to enable secondary trading.

## Important Functions

- `deploy()`: Set up a new memecoin.
- `buy()`: Allow users to buy tokens during the sale.
- `sell()`: Allow users to sell tokens during the sale.

For detailed information on function parameters and usage, please refer to the contract documentation.

## Contract Structure

- `CoopFactory.sol`: The main implementation contract containing all the logic for the Coop factory.
- `Coop.sol`: A proxy contract that delegates calls to the implementation contract, allowing for upgrades.

For more details on implementation, please refer to the contract source code and comments.
