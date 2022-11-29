// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";

contract TestCampaign is Helpers {
    Vault public vault;
    IERC20 public USDCContract;

    function setUp() public {
        vault = new Vault();
        USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    // Test to find if minting of nft is possible and the USDC is sent to the vault
    function testMintingAndReceivingUSDC(
        Vault.timelockContractArguments memory newStruct,
        Vault.govTokenContractArguments memory _govTokenContractArguments
    ) public {
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            0x8C8D7C46219D9205f056f28fee5950aD564d7465,
            vault,
            newStruct,
            _govTokenContractArguments
        );
        // Minting an NFT by another address that has some USDC
        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        vm.stopPrank();

        assertEq(
            nftContract.balanceOf(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2),
            1
        );
        assertEq(USDCContract.balanceOf(address(vault)), 20000000);
        CampaignFactory campaignFactory = CampaignFactory(
            payable(campaignAddress)
        );
        assertEq(
            campaignFactory.balanceOf(
                0x1B7BAa734C00298b9429b518D621753Bb0f6efF2
            ),
            20 * 10**18
        );
    }

    function testProposeAndExecute(Vault.govTokenContractArguments memory _govTokenContractArguments) public {
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
        // Minting by 1st Person
        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        // delegating
        campaignFactory.delegate(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        vm.stopPrank();

        // Minting by 2nd Person
        vm.startPrank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        USDCContract.approve(address(nftContract), 20000000);
        nftContract.safeMint();
        campaignFactory.delegate(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
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

        // Moving 11 Blocks for the voting to begin since we gave voting delay as 10
        vm.roll(block.number + 11);
        assertEq(uint256(campaignFactory.state(proposalId)), 1);

        // 1st person voting. 1 is for
        vm.prank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);
        campaignFactory.castVote(proposalId, 1);

        // 2nd person voting.
        vm.prank(0x89dF4F398563bF6A64a4D24dFE4be00b20b563Ae);
        campaignFactory.castVote(proposalId, 1);

        // Moving blocks for the voting to end
        vm.roll(block.number + 11);
        // 4 is the suceeded state
        assertEq(uint256(campaignFactory.state(proposalId)), 4);

        queingAndExecuting(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2, proposalId, campaignFactory, proposalDesc, vaultAddress, calldataValue, encodedFunctionCall);

        assertEq(uint256(campaignFactory.state(proposalId)), 7);
        assertEq(
            USDCContract.balanceOf(
                vault.getCampaign(address(nftContract)).multisig
            ),
            3000000
        );
    }

    function proposalExecution(string memory proposalDesc, NFTContract nftContract, CampaignFactory campaignFactory) private returns(uint256){
        bytes[] memory encodedFunctionCall = new bytes[](1);
        encodedFunctionCall[0] = abi.encodeWithSignature(
            "releaseFunds(address)",
            [address(nftContract)]
        );
        

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

        return proposalId;
    }

    function testEntireCampaign(Vault.govTokenContractArguments memory _govTokenContractArguments) public{
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault.timelockContractArguments(2, proposers, executors);
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

        // Create and Execute 1st Proposal
        string memory proposalDesc = "Something related to proposal";
        uint256 propId = proposalExecution(proposalDesc, nftContract, campaignFactory);

        address multisigAddress = vault.getCampaign(address(nftContract)).multisig;
        assertEq(
            USDCContract.balanceOf(multisigAddress),
            3000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentFunds, 37000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentStage, 2
        );

        // Create and Execute 2nd Proposal
        string memory proposalDesc2 = "Something related to proposal2";
        uint256 propId2 = proposalExecution(proposalDesc2, nftContract, campaignFactory);
    
        assertEq(
            USDCContract.balanceOf(multisigAddress),
            5000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentFunds, 35000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentStage, 3
        );

         // Create and Execute 3rd Proposal
        string memory proposalDesc3 = "Something related to proposal3";
        uint256 propId3 = proposalExecution(proposalDesc3, nftContract, campaignFactory);
    
        assertEq(
            USDCContract.balanceOf(multisigAddress),
            10000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentFunds, 30000000
        );
        assertEq(
            vault.getCampaign(address(nftContract)).currentStage, 4
        );
    }
}