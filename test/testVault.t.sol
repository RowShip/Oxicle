// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";

contract TestVault is Test {
    Vault public vault;

    function setUp() public {
        vault = new Vault();
    }

    function testSetupACampaign(
        address _nftContractAddress,
        Vault.timelockContractArguments memory _timeLockContractArguments
    ) public {
        address[] memory signatories = new address[](2);
        signatories[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.MultiSig memory _multisig = Vault.MultiSig(signatories, 1);

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0] = 300000;
        fundsPerStage[0] = 200000;
        fundsPerStage[0] = 500000;

        address newlyCreatedCampaign = vault.setupCampaign(
            _nftContractAddress,
            _timeLockContractArguments,
            3,
            fundsPerStage,
            1000000,
            _multisig
        );

        assertEq(
            address(vault.getCampaign(address(_nftContractAddress)).campaign),
            newlyCreatedCampaign
        );
    }
}