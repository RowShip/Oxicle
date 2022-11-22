// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "src/Vault.sol";
import "forge-std/Script.sol";
import "../src/NFTOwnersEnd/NftContract.sol";

contract VaultScript is Script {
    Vault public vault;
    function setUp() public {
    }

    // Deploying Vault and then creating campaign
    function run() public {
        vm.startBroadcast();
        vault = new Vault();

        NFTContract nftContract = new NFTContract(address(vault));

        address[] memory signatories = new address[](2);
        signatories[0] = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
        signatories[1] = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
        Vault.MultiSig memory _multisig = Vault.MultiSig(signatories, 1);

        address[] memory proposer = new address[](1);
        proposer[0] = address(0);
        address[] memory executor = new address[](1);
        executor[0] = address(0);
        Vault.timelockContractArguments memory newStruct = Vault.timelockContractArguments(5, proposer, executor);

        uint256[] memory fundsPerStage = new uint256[](3);
        fundsPerStage[0] = 300000;
        fundsPerStage[0] = 200000;
        fundsPerStage[0] = 500000;

        vault.setupCampaign(
            address(nftContract),
            newStruct,
            3,
            fundsPerStage,
            1000000,
            _multisig
        );

        vm.stopBroadcast();
    }
}