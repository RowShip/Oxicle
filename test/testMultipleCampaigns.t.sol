// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";
import "forge-std/console.sol";


contract TestMultipleCampaigns is Helpers {
    Vault public vault;
    IERC20 public USDCContract;

    function setUp() public {
        vault = new Vault();
        USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function testCreationOfMultipleCampaigns(Vault.timelockContractArguments memory newStruct, Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        vm.startPrank(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        vm.stopPrank();

        assertEq(
            nftContract.balanceOf(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4),
            1
        );
        assertEq(USDCContract.balanceOf(address(vault)), 20000000);

        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );
        assertEq(
            campaignFactory.balanceOf(
                0x4943b0C9959dcf58871A799dfB71becE0D97c9f4
            ),
            20 * 10**18
        );
        

        (NFTContract nftContract2, address campaignAddress2) = createCampaign(
            0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        vm.startPrank(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        USDCContract.approve(address(nftContract2), 20000000);
        nftContract2.safeMint();
        vm.stopPrank();

        // assertEq(vault.allCampaigns(address(nftContract2)).currentFunds, 20000000);
        assertEq(
            nftContract2.balanceOf(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A),
            1
        );
        assertEq(USDCContract.balanceOf(address(vault)), 40000000);

        CampaignFactory campaignFactory2 = CampaignFactory(
            payable(campaignAddress2)
        );
        assertEq(
            campaignFactory2.balanceOf(
                0xee5B5B923fFcE93A870B3104b7CA09c3db80047A
            ),
            20 * 10**18
        );

        (NFTContract nftContract3, address campaignAddress3) = createCampaign(
            0xBE0eB53F46cd790Cd13851d5EFf43D12404d33E8,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        vm.startPrank(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        USDCContract.approve(address(nftContract3), 20000000);
        nftContract3.safeMint();
        vm.stopPrank();

        // assertEq(vault.allCampaigns(address(nftContract3)).currentFunds, 20000000);

        assertEq(
            nftContract3.balanceOf(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17),
            1
        );
        assertEq(USDCContract.balanceOf(address(vault)), 60000000);

        CampaignFactory campaignFactory3 = CampaignFactory(
            payable(campaignAddress3)
        );
        assertEq(
            campaignFactory3.balanceOf(
                0xDa9CE944a37d218c3302F6B82a094844C6ECEb17
            ),
            20 * 10**18
        );

    }

    function testProposalsForMultipleCampaigns(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault
            .timelockContractArguments(2, proposers, executors);
        // First Campaign
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );
        vm.startPrank(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        vm.stopPrank();
        vm.startPrank(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        vm.stopPrank();
        vm.startPrank(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        vm.stopPrank();

         // Second Campaign
        (NFTContract nftContract2, address campaignAddress2) = createCampaign(
            0x0716a17FBAeE714f1E6aB0f9d59edbC5f09815C0,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        CampaignFactory campaignFactory2 = CampaignFactory(
            payable(campaignAddress2)
        );
        vm.startPrank(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        USDCContract.approve(address(nftContract2), 20000000);
        nftContract2.safeMint();
        campaignFactory2.delegate(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        vm.stopPrank();
        vm.startPrank(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        USDCContract.approve(address(nftContract2), 20000000);
        nftContract2.safeMint();
        campaignFactory2.delegate(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        vm.stopPrank();
        vm.startPrank(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory2.delegate(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        vm.stopPrank();
        

        // creating proposal
        bytes[] memory encodedFunctionCall = new bytes[](1);
        encodedFunctionCall[0] = abi.encodeWithSignature(
            "releaseFunds(address)",
            [address(nftContract)]
        );
        string memory proposalDesc = "Something related to proposal";

        (
            uint256 proposalId,
            address[] memory vaultAddress,
            uint256[] memory calldataValue
        ) = createProposal(
                0x1B7BAa734C00298b9429b518D621753Bb0f6efF2,
                vault,
                campaignFactory,
                encodedFunctionCall,
                proposalDesc
            );


        assertEq(uint256(campaignFactory.state(proposalId)), 0);
        vm.stopPrank();

        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory.state(proposalId)), 1);

        vm.prank(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        campaignFactory.castVote(proposalId, 1);

        vm.prank(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        campaignFactory.castVote(proposalId, 1);

        vm.prank(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        campaignFactory.castVote(proposalId, 1);

        vm.roll(block.number + 11);
        console.log(uint256(campaignFactory.state(proposalId)));
        assertEq(uint256(campaignFactory.state(proposalId)), 4);

        bytes32 descriptionHash = keccak256("Something related to proposal");
        campaignFactory.queue(
            vaultAddress,
            calldataValue,
            encodedFunctionCall,
            descriptionHash
        );

        vm.roll(block.number + 11);
        vm.warp(block.timestamp + 4);
        assertEq(uint256(campaignFactory.state(proposalId)), 5);

        campaignFactory.execute(
            vaultAddress,
            calldataValue,
            encodedFunctionCall,
            descriptionHash
        );



        assertEq(uint256(campaignFactory.state(proposalId)), 7);
        // assertEq(
        //     USDCContract.balanceOf(vault.getCampaign(address(nftContract)).multisig),
        //     3000000
        // );


        // Second Campaign Proposal

        bytes[] memory encodedFunctionCall1 = new bytes[](1);
        encodedFunctionCall1[0] = abi.encodeWithSignature(
            "releaseFunds(address)",
            [address(nftContract2)]
        );
        string memory proposalDesc1 = "Something related to proposal 2";

        (
            uint256 proposalId1,
            address[] memory vaultAddress1,
            uint256[] memory calldataValue1
        ) = createProposal(
                0x1B7BAa734C00298b9429b518D621753Bb0f6efF2,
                vault,
                campaignFactory2,
                encodedFunctionCall1,
                proposalDesc1
            );

        assertEq(uint256(campaignFactory2.state(proposalId1)), 0);

        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory2.state(proposalId1)), 1);

        vm.prank(0x4943b0C9959dcf58871A799dfB71becE0D97c9f4);
        campaignFactory2.castVote(proposalId1, 1);

        vm.prank(0xee5B5B923fFcE93A870B3104b7CA09c3db80047A);
        campaignFactory2.castVote(proposalId1, 1);

        vm.prank(0xDa9CE944a37d218c3302F6B82a094844C6ECEb17);
        campaignFactory2.castVote(proposalId1, 1);

        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory2.state(proposalId1)), 4);

        queingAndExecuting(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, proposalId1, campaignFactory2, proposalDesc1, vaultAddress1, calldataValue1, encodedFunctionCall1);
        
        assertEq(uint256(campaignFactory2.state(proposalId1)), 7);
        // assertEq(
        //     USDCContract.balanceOf(vault.getCampaign(address(nftContract2)).multisig),
        //     3000000
        // );
        

       


    
    }
}