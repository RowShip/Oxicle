// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Timelock.sol";

library DeployTimelock{
    function createTimelockContract(uint256 _minDelay) public returns(TimeLock){
        address[] memory t = new address[](0);
        TimeLock newTimelock = new TimeLock(_minDelay, t,t);
        return newTimelock;
    }
}