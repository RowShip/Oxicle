// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";
import "../../src/Vault.sol";
import "../../src/CampaignFactory.sol";
import "../../src/NFTOwnersEnd/NftContract.sol";
import "../../src/openzeppelin/governance/IGovernor.sol";
import "../../src/openzeppelin/token/ERC20/IERC20.sol";

// For Testing
import "forge-std/console.sol";

contract Helpers is Test{

    function createCampaign(Vault vault, Vault.timelockContractArguments memory _timeLockContractArguments) public returns(NFTContract, address){
        // Impersonating nftContract creator. It can be any address - just to show that this was executed by another address
        vm.startPrank(0x8C8D7C46219D9205f056f28fee5950aD564d7465);
        // Creating an NFt contract
        NFTContract nftContract = new NFTContract(address(vault));

        address[] memory signatories = new address[](2);
        signatories[0]=0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1]=0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.MultiSig memory _multisig = Vault.MultiSig(
            signatories,
            1
        );

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0]=3000000;
        fundsPerStage[1]=2000000;
        fundsPerStage[2]=5000000;

        address newlyCreatedCampaign = vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            3,
            fundsPerStage,
            10000000,
            _multisig
        );
        
        assertEq(address(vault.getCampaign(address(nftContract)).campaign),newlyCreatedCampaign);
        vm.stopPrank();
        return (nftContract, newlyCreatedCampaign);
    }

}