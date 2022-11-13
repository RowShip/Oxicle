// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GovernanceToken.sol";
import "./Vault.sol";


library DeployGovToken{
    
    function createGovTokenContract(Vault.ForGovToken calldata _govTok) public returns(GovernanceToken){
        GovernanceToken newGovToken = new GovernanceToken(
            _govTok._govTokenName,
            _govTok._govTokenSymbol
        );
        return newGovToken;
    }

}