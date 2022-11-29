// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GovernanceToken.sol";
import "./Timelock.sol";
import "./GovernorContract.sol";
import "./Vault.sol";

// TODO: For Testing. Remove after testing
import "forge-std/console.sol";

contract CampaignFactory is GovernanceToken ,TimeLock, GovernorContract {

    constructor(
        // string memory _GovTokenName,
        // string memory _GovTokenSymbol,
        address _nftContractAddress,
        Vault.timelockContractArguments memory _timelockContractArguments,
        Vault.govTokenContractArguments memory _govTokenContractArguments,
        Vault.governorContractArguments memory _governorContractArguments,
        address _vault
    ) 
        TimeLock(_timelockContractArguments)
        GovernorContract(
            _governorContractArguments,
            _nftContractAddress,
            _vault
        )
        GovernanceToken(_govTokenContractArguments._govTokenName, _govTokenContractArguments._govTokenSymbol)
    {
        // TODO: Need to check if this is correct
        grantRole(PROPOSER_ROLE, address(this));
        grantRole(EXECUTOR_ROLE, address(0));
        // //Revoking role here
        revokeRole(TIMELOCK_ADMIN_ROLE, msg.sender);
    }


    // Below are all Overrides that were added because of inheriting the contracts
    // We are overriding two different contracts here EIP712 and EIP712_NoConst
    // And all the below three functions are the same inside these two contracts. Including the implementation.
    // So, implementing with super keyword might work
    
    function _domainSeparatorV4() public override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._domainSeparatorV4();
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) public virtual override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._buildDomainSeparator(typeHash, nameHash, versionHash);
    }

    function _hashTypedDataV4(bytes32 structHash) public virtual override(EIP712,EIP712_NoConst) view returns (bytes32) {
        return super._hashTypedDataV4(structHash);
    }


    // TODO: not sure if  onERC721Received, onERC1155Received, onERC1155BatchReceived, supportsInterface, and receive are imported correctly
    // These function are used when we are expecting tokens like erc721, erc1155 etc. But I am unsure what these actually do here. Need to check

    // the below 3 functions will work fine.
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public override(TimelockController, Governor) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public override(TimelockController, Governor) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public override(TimelockController, Governor) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    // This might work
    function supportsInterface(bytes4 interfaceId) public view override(TimelockController, GovernorContract) returns (bool) {
        return
            interfaceId ==
            (type(IGovernor).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            interfaceId == type(IGovernor).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // TODO: For this, We can do either of the two things:
    // 1. Delete the receive() function on the other contracts and only implement it here. 
    // 2. Override like we did here and keep the other functions untouched
    // Currently I have implemented the 1st option
    receive() external payable {
        require(_executor() == address(this));
    }


    // TODO: change the return value of this name() function.
    // This function actually returns the name of - For egs: ERC20 token.
    // So, since we are overriding this - The name of erc20 token(governance token) and the name of the governor instance will be the same and that which we give below
    // So, basically - the name of gov token and governor will be the same, you won't be able to give different values for both
  function name() public view virtual override(ERC20, Governor, IGovernor) returns (string memory) {
        return "Governance";
    }
}   