// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";

contract RemovingCampaigns is Helpers {
    Vault public vault;
    IERC20 public USDCContract;

    function setUp() public {
        vault = new Vault();
        USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    function createProposeExecute(Vault.govTokenContractArguments memory _govTokenContractArguments) public returns(uint256, NFTContract, CampaignFactory){
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault
            .timelockContractArguments(2, proposers, executors);
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );

        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.stopPrank();

        vm.startPrank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        vm.stopPrank();


        bytes[] memory encodedFunctionCall = new bytes[](1);
        encodedFunctionCall[0] = abi.encodeWithSignature(
            "removeCampaign(address)",
            [address(nftContract)]
        );
        string memory proposalDesc = "Something related to proposal 1";

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

        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory.state(proposalId)), 1);

        vm.prank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        campaignFactory.castVote(proposalId, 1);

        vm.prank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        campaignFactory.castVote(proposalId, 1);

        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory.state(proposalId)), 4);

        queingAndExecuting(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, proposalId, campaignFactory, proposalDesc, vaultAddress, calldataValue, encodedFunctionCall);
        return (proposalId, nftContract, campaignFactory);
    }

    function withdrawFunds(address _investor, NFTContract nftContract, uint256 _tokenId) private returns(uint256){
        uint256 balanceBefore = USDCContract.balanceOf(_investor);
        vm.prank(_investor);
        vault.withdrawFundsAfterCampaignRemoval(address(nftContract), _tokenId);
        uint256 balanceAfter = USDCContract.balanceOf(_investor);
        uint256 bal = balanceAfter - balanceBefore;
        return bal;
    }
    
    function testRemovalOfCampaign(Vault.govTokenContractArguments memory _govTokenContractArguments) public{

        (uint256 proposalId, NFTContract nftContract, CampaignFactory campaignFactory) = createProposeExecute(_govTokenContractArguments);
        
        assertEq(uint256(campaignFactory.state(proposalId)), 7);
        assertEq(vault.getCampaign(address(nftContract)).campaignRemoved, true);
    }

    function testWithdrawFundsAfterCampaignRemoval(Vault.govTokenContractArguments memory _govTokenContractArguments) public{

        (uint256 proposalId, NFTContract nftContract, CampaignFactory campaignFactory) = createProposeExecute(_govTokenContractArguments);

        // 1st person withdrawing
        uint256 bal = withdrawFunds(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, nftContract, 0);
        assertEq(bal, 20000000);

        // 2nd person withdrawing
        uint256 bal2 = withdrawFunds(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae, nftContract, 1);
        assertEq(bal2, 20000000);

    }

    function testAnyoneCannotWithdraw(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        (uint256 proposalId, NFTContract nftContract, CampaignFactory campaignFactory) = createProposeExecute(_govTokenContractArguments);
        vm.startPrank(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4);
        vm.expectRevert("You are not Authorized");
        vault.withdrawFundsAfterCampaignRemoval(address(nftContract), 1);
        vm.stopPrank();
    }

    function testMultipleWithdrawalsIsNotPossible(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        (uint256 proposalId, NFTContract nftContract, CampaignFactory campaignFactory) = createProposeExecute(_govTokenContractArguments);

        vm.startPrank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        vault.withdrawFundsAfterCampaignRemoval(address(nftContract), 1);
        
        vm.expectRevert("You have already claimed once");
        vault.withdrawFundsAfterCampaignRemoval(address(nftContract), 1);
        vm.stopPrank();
    }

    function testWithdrawalBeforeCampaignRemoval(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault
            .timelockContractArguments(2, proposers, executors);
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );

        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.stopPrank();

        vm.startPrank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        vm.stopPrank();

        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.expectRevert("the campaign is not removed yet");
        vault.withdrawFundsAfterCampaignRemoval(address(nftContract), 0);
        vm.stopPrank();

    }

    function testRemovingAfterReleasingStageOneFunds(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault
            .timelockContractArguments(2, proposers, executors);
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );

        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );

        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.stopPrank();

        vm.startPrank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        vm.stopPrank();

        // creating proposal for releasing funds
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


        vm.roll(block.number + 11);

        vm.prank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        campaignFactory.castVote(proposalId, 1);

        vm.prank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        campaignFactory.castVote(proposalId, 1);

        vm.roll(block.number + 11);

        queingAndExecuting(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, proposalId, campaignFactory, proposalDesc, vaultAddress, calldataValue, encodedFunctionCall);


        // Proposal for Removing campaign
        bytes[] memory encodedRemoveFunctionCall = new bytes[](1);
        encodedRemoveFunctionCall[0] = abi.encodeWithSignature(
            "removeCampaign(address)",
            [address(nftContract)]
        );
        string memory removeProposalDesc = "Something related to proposal 1";

        (
            uint256 removeProposalId,
            address[] memory vaultAddress1,
            uint256[] memory calldataValue1
        ) = createProposal(
                0x1B7BAa734C00298b9429b518D621753Bb0f6efF2,
                vault,
                campaignFactory,
                encodedRemoveFunctionCall,
                removeProposalDesc
            );

        vm.roll(block.number + 11);

        vm.prank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        campaignFactory.castVote(removeProposalId, 1);

        vm.prank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        campaignFactory.castVote(removeProposalId, 1);

        vm.roll(block.number + 11);

        queingAndExecuting(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, removeProposalId, campaignFactory, removeProposalDesc, vaultAddress1, calldataValue1, encodedRemoveFunctionCall);

        // 1st person withdrawing
        uint256 bal = withdrawFunds(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, nftContract, 0);
        assertEq(bal, 18500000);

    }
}