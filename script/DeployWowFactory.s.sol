// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/Script.sol";
import {WowFactoryImpl} from "../src/WowFactoryImpl.sol";
import {WowFactory} from "../src/WowFactory.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {Wow} from "../src/Wow.sol";

/*
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNXK0OkkkkkkO0KXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNOdl:'...        ...':lx0XWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMW0d:.                        .:d0NMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.                              .;dKWMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMW0l.                                    .l0WMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMNKOkkxkO0KOl.                                        .lKWMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMW0l'.       ..                                            'xNMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMO'   .',,,.                                                .lXMMMMMMMMMMMMMMMMMM
MMMMMMMMMWo   ,0NWWK:                                                  cXMMMMMMMMMMMMMMMMM
MMMMMMMMMMk.  .xWMNo                      .',,,,'.                      oNMMMMMMMMMMMMMMMM
MMMMMMMMMMNo.  .oXx.                  .,oOKNWWWWNKOo,                   .kWMMMMMMMMMMMMMMM
MMMMMMMMMMMNx.   '.                  ,kNMMMMMMMMMMMMNk,                  :XMMMMMMMMMMMMMMM
MMMMMMMMMMMMW0:.                    cXMMMMMMMMMMMMMMMMK:                 .kMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMNk;                  ,0MMMMMMXkddkNMMMMMM0'                 dWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMNk;                cNMMMMMNo   .oWMMMMMX:                 oWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMNO:.             ;XMMMMMW0c;;l0WMMMMMK,                 oWMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMW0l'           .dWMMMMMMMWWMMMMMMMNo.                .kMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMNO0WMMXx:.         .oXMMMMMMMMMMMMMMXl.                 ,KMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMWd';xXWMWKd;.        'o0NMMMMMMMWNOo'                  .dWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMX:  .lONMMW0o,.       .':looool:'.                    .OWMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMM0;    ,o0NMMN0d;.                                     'dNMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMM0;     .,o0NMMWKxc.                               ..   :0WMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMXl.      .,lONWMWXOo;.                         .lK0;   'OWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMNk,         'cxKWMMWKkl:;.                   ,kWMMXl   ,0MMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMXd'          .,lkXWMMMWKko;..            .oXMMMMM0,  .dWMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMXx;.           .;ok0XWMMWX0xl;..       .,;cclcc,   .kMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMWKd;.            ..;lx0NWMMWX0koc;'..          .;kWMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXko:,..           .'cxKWMMMMMWNK0OxdolllodkKWMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNX0kxolllccllooxk0NWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM
*/
contract DeployWowFactory is Script {
    function run() public {
        vm.startBroadcast();
        address COOP_RECS = 0x512b55b00d744fC2eDB8474f223a7498c3e5a7ce; // CoopRecs.base.eth

        // Wow constructor addresses
        address protocolFeeRecipient = COOP_RECS;
        address protocolRewards = 0x7777777F279eba3d3Ad8F4E708545291A6fDBA8B; // Base Sepolia ProtocolRewards
        address weth = 0x4200000000000000000000000000000000000006; // Base Sepolia WETH
        address nonfungiblePositionManager = 0x27F971cb582BF9E50F397e4d29a5C7A34f11faA2; // Base Sepolia NonfungiblePositionManager
        address swapRouter = 0x94cC0AaC535CCDB3C01d6787D6413C739ae12bc4; // Base Sepolia Swap Router

        // Deploy Wow token implementation
        address tokenImplementation = address(
            new Wow(
                protocolFeeRecipient,
                protocolRewards,
                weth,
                nonfungiblePositionManager,
                swapRouter
            )
        );

        address bondingCurve = 0x31eb0D332F0C13836CCEC763989915d0195AE494;
        address defaultOwner = COOP_RECS;

        // Deploy WowFactoryImpl
        WowFactoryImpl wowFactoryImpl = new WowFactoryImpl(
            tokenImplementation,
            bondingCurve
        );

        // Initialize data for proxy
        bytes memory initData = abi.encodeWithSelector(
            WowFactoryImpl.initialize.selector,
            defaultOwner
        );

        // Deploy proxy
        WowFactory proxy = new WowFactory(address(wowFactoryImpl), initData);

        console2.log("Factory proxy deployed to:", address(proxy));

        vm.stopBroadcast();
    }
}
