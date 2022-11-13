// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./GovernorContract.sol";
import "./GovernanceToken.sol";
import "./Timelock.sol";
import "./Vault.sol";


library DeployGovernor{

    function createGovernorContract(GovernanceToken _newGovToken,TimeLock _newTimelock, Vault.ForGovernor calldata _GovernorCont, uint256 _id, address _vault) public returns(GovernorContract){
        GovernorContract newGovernor = new GovernorContract(
            _newGovToken,
            _newTimelock,
            _GovernorCont._quorumPercentage,
            _GovernorCont._votingPeriod,
            _GovernorCont._votingDelay,
            _id,
            _vault
        );
        return newGovernor;
    }
    
}