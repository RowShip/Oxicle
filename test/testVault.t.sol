// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import {Vault} from "../src/Vault.sol";
import "../src/NFTOwnersEnd/NftContract.sol";

contract TestVault is Test {
    Vault public vault;

    function setUp() public {
        vault = new Vault();
    }

    function testSetupACampaign(
        Vault.timelockContractArguments memory _timeLockContractArguments,
        Vault.govTokenContractArguments memory _govTokenContractArguments
    ) public {
        NFTContract nftContract = new NFTContract(address(vault));

        address[] memory signatories = new address[](2);
        signatories[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.multisigContractArguments memory _multisig = Vault
            .multisigContractArguments(signatories, 1);

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0] = 300000;
        fundsPerStage[1] = 200000;
        fundsPerStage[2] = 500000;

        Vault.governorContractArguments
            memory _governorContractArguments = Vault.governorContractArguments(
                5,
                10,
                10
            );

        address newlyCreatedCampaign = vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            _governorContractArguments,
            _govTokenContractArguments,
            3,
            fundsPerStage,
            1000000,
            _multisig
        );

        assertEq(
            address(vault.getCampaign(address(nftContract)).campaign),
            newlyCreatedCampaign
        );
    }

    function testSetupCampaignInvalidArguments(
        Vault.timelockContractArguments memory _timeLockContractArguments,
        Vault.govTokenContractArguments memory _govTokenContractArguments
    ) public {
        NFTContract nftContract = new NFTContract(address(vault));

        address[] memory signatories = new address[](2);
        signatories[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.multisigContractArguments memory _multisig = Vault
            .multisigContractArguments(signatories, 1);

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0] = 300000;
        fundsPerStage[1] = 200000;
        fundsPerStage[2] = 500000;

        Vault.governorContractArguments
            memory _governorContractArguments = Vault.governorContractArguments(
                5,
                10,
                10
            );

        vm.expectRevert("Error! FundsPerStage not matching the no of stages");
        vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            _governorContractArguments,
            _govTokenContractArguments,
            4,
            fundsPerStage,
            1000000,
            _multisig
        );

        uint256[] memory fundsPerStage1 = new uint256[](0);
        vm.expectRevert("totalStages or TotalFundsRequired cannot be 0");
        vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            _governorContractArguments,
            _govTokenContractArguments,
            0,
            fundsPerStage1,
            1000000,
            _multisig
        );

        vm.expectRevert("Wrong number of signatories or Quorum given");
        vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            _governorContractArguments,
            _govTokenContractArguments,
            3,
            fundsPerStage,
            1000000,
            Vault.multisigContractArguments(signatories, 0)
        );
    }
}