// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";

contract TestNotAllowed is Helpers {
    Vault public vault;

    function setUp() public {
        vault = new Vault();
    }

    function testUnauthorizedFunctionsWithRandomAccount(Vault.timelockContractArguments memory newStruct, Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );
        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.expectRevert("You are not authorized");
        vault.releaseFunds(address(nftContract));
        vm.expectRevert("You are not authorized");
        vault.removeCampaign(address(nftContract));
        vm.expectRevert("You are not authorized");
        vault.supplyFundsToCampaign(1000);
        vm.expectRevert("You are not authorized");
        vault.mintGovernanceTokens(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2,1000);

        CampaignFactory _campaignFactory = CampaignFactory(payable(campaignAddress));
        vm.expectRevert("Ownable: caller is not the owner");
        _campaignFactory.mint(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, 10000000);
        vm.stopPrank();
    }

    function testCampaignCreationTwoTimesWithSameNftContract(Vault.timelockContractArguments memory newStruct, Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        // Creating a new campaign with the same nft contract
        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        address[] memory signatories = new address[](2);
        signatories[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.multisigContractArguments memory _multisig = Vault.multisigContractArguments(signatories, 1);

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0] = 3000000;
        fundsPerStage[1] = 2000000;
        fundsPerStage[2] = 5000000;

        Vault.governorContractArguments memory _governorContractArguments = Vault.governorContractArguments(
                5,
                10,
                10
            );

        vm.expectRevert("Given Nft contract already uses this protocol");
        address newlyCreatedCampaign = vault.setupCampaign(
            address(nftContract),
            newStruct,
            _governorContractArguments,
            _govTokenContractArguments,
            3,
            fundsPerStage,
            10000000,
            _multisig
        );
        vm.stopPrank();
    }
    
}