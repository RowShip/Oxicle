// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";

contract TestNotAllowed is Helpers {
    Vault public vault;

    function setUp() public {
        vault = new Vault();
    }

    function testUnauthorizedFunctionsWithRandomAccount(Vault.timelockContractArguments memory newStruct) public{
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct
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
        vm.stopPrank();
    }
    
}