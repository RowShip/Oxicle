// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./utils/helpers.t.sol";

contract TestVault is Helpers {
    Vault public vault;
    IERC20 public USDCContract;

    function setUp() public {
        vault = new Vault();
        USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    // Test to find if minting of nft is possible and the USDCContract is sent to the vault
    function testMintingAndReceivingUSDC(Vault.timelockContractArguments memory newStruct)
        public
    {
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            vault,
            newStruct
        );
        // Minting an NFT by another address that has some USDCContract
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

    function testProposeAndExecute() public {
        address[] memory proposers = new address[](1);
        address[] memory executors = new address[](1);
        Vault.timelockContractArguments memory newStruct = Vault.timelockContractArguments(
            2,
            proposers,
            executors
        );
        (NFTContract nftContract, address campaignAddress) = createCampaign(
            vault,
            newStruct
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
        vm.startPrank(0x1B7BAa734C00298b9429b518D621753Bb0f6efF2);

        bytes[] memory encodedFunctionCall = new bytes[](1);
        encodedFunctionCall[0] = abi.encodeWithSignature(
            "releaseFunds(address)",
            [address(nftContract)]
        );
        string memory proposalDesc = "Something related to proposal";
        address[] memory vaultAddress = new address[](1);
        vaultAddress[0] = address(vault);
        uint256[] memory calldataValue = new uint256[](1);
        calldataValue[0] = uint256(0);
        uint256 proposalId = campaignFactory.propose(
            vaultAddress,
            calldataValue,
            encodedFunctionCall,
            proposalDesc
        );

        assertEq(uint256(campaignFactory.state(proposalId)), 0);
        vm.stopPrank();

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

        // Queing
        bytes32 descriptionHash = keccak256("Something related to proposal");
        campaignFactory.queue(
            vaultAddress,
            calldataValue,
            encodedFunctionCall,
            descriptionHash
        );

        // Moving block to move past the min delay
        vm.warp(block.timestamp + 3);
        assertEq(uint256(campaignFactory.state(proposalId)), 5);

        // Finally, Executing
        campaignFactory.execute(
            vaultAddress,
            calldataValue,
            encodedFunctionCall,
            descriptionHash
        );

        assertEq(uint256(campaignFactory.state(proposalId)), 7);
        assertEq(
            USDCContract.balanceOf(vault.getCampaign(address(nftContract)).multisig),
            3000000
        );
    }
}