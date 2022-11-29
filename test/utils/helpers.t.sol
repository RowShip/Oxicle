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

contract Helpers is Test {
    function createCampaign(
        address _campaignCreator,
        Vault vault,
        Vault.timelockContractArguments memory _timeLockContractArguments,
        Vault.govTokenContractArguments memory _govTokenContractArguments
    ) public returns (NFTContract, address) {
        // Impersonating nftContract creator. It can be any address - just to show that this was executed by another address
        vm.startPrank(_campaignCreator);
        // Creating an NFt contract
        NFTContract nftContract = new NFTContract(address(vault));

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

        address newlyCreatedCampaign = vault.setupCampaign(
            address(nftContract),
            _timeLockContractArguments,
            _governorContractArguments,
            _govTokenContractArguments,
            3,
            fundsPerStage,
            10000000,
            _multisig
        );

        assertEq(
            address(vault.getCampaign(address(nftContract)).campaign),
            newlyCreatedCampaign
        );
        vm.stopPrank();
        return (nftContract, newlyCreatedCampaign);
    }

    function createProposal(
        address _proposalCreator,
        Vault _vault,
        CampaignFactory _campaignFactory,
        bytes[] memory _encodedFunctionCall,
        string memory _proposalDesc
    )
        public
        returns (
            uint256,
            address[] memory,
            uint256[] memory
        )
    {
        vm.startPrank(_proposalCreator);
        address[] memory vaultAddress = new address[](1);
        vaultAddress[0] = address(_vault);
        uint256[] memory calldataValue = new uint256[](1);
        calldataValue[0] = uint256(0);
        uint256 proposalId = _campaignFactory.propose(
            vaultAddress,
            calldataValue,
            _encodedFunctionCall,
            _proposalDesc
        );
        vm.stopPrank();
        return (proposalId, vaultAddress, calldataValue);
    }

    function queingAndExecuting(
        address _executor,
        uint256 _proposalId,
        CampaignFactory _campaignFactory,
        string memory _proposalDesc,
        address[] memory _vaultAddress,
        uint256[] memory _calldataValue,
        bytes[] memory _encodedFunctionCall
    ) public {
        // Queing
        vm.prank(_executor);
        bytes32 descriptionHash = keccak256(abi.encodePacked(_proposalDesc));
        _campaignFactory.queue(
            _vaultAddress,
            _calldataValue,
            _encodedFunctionCall,
            descriptionHash
        );

        // Moving block to move past the min delay
        vm.warp(block.timestamp + 3);
        assertEq(uint256(_campaignFactory.state(_proposalId)), 5);

        // Finally, Executing
        _campaignFactory.execute(
            _vaultAddress,
            _calldataValue,
            _encodedFunctionCall,
            descriptionHash
        );
        vm.stopPrank();
    }
}