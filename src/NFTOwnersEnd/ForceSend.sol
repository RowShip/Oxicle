// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../openzeppelin/token/ERC20/IERC20.sol";

interface IVaultInterface{
    function supplyFundsToCampaign(uint256 _amount) external;
    function mintGovernanceTokens(address _to, uint256 _amount) external;
}

contract ForceSend{

    // TODO: Hardcode Vault address.
    // Currently used just for testing
    address public vaultAddress;
    IVaultInterface public vaultContract;
    IERC20 public USDCContract;


    constructor(address _vaultAddress) {
        vaultAddress = _vaultAddress;
        vaultContract = IVaultInterface(vaultAddress);
        USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    }

    modifier sendToVault(uint256 _amount){
        USDCContract.transferFrom(msg.sender, vaultAddress, _amount);
        vaultContract.supplyFundsToCampaign(_amount);
        vaultContract.mintGovernanceTokens(msg.sender, _amount);
        _;
    }
}