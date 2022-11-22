// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./openzeppelin/governance/TimelockController.sol";
import "./Vault.sol";

contract TimeLock is TimelockController {
  constructor(
    Vault.timelockContractArguments memory _timelock
  ) TimelockController(_timelock._minDelay, _timelock._proposers, _timelock._executors) {}
}