// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/governance/Governor.sol";
import "./openzeppelin/governance/extensions/GovernorCountingSimple.sol";
import "./openzeppelin/governance/extensions/GovernorVotes.sol";
import "./openzeppelin/governance/extensions/GovernorVotesQuorumFraction.sol";
import "./openzeppelin/governance/extensions/GovernorTimelockControl.sol";
import "./openzeppelin/governance/extensions/GovernorSettings.sol";
import "./chainlink/KeeperCompatibleInterface.sol";
import "./Vault.sol";


interface IVault{
  function getCurrentStage(address _nftContractAddress) external view returns(uint256);
}

contract GovernorContract is
  KeeperCompatibleInterface,
  Governor,
  GovernorSettings,
  GovernorCountingSimple,
  GovernorVotes,
  GovernorVotesQuorumFraction,
  GovernorTimelockControl
{
    address public nftContractAddress;
    IVault public vault; 

  constructor(
    Vault.governorContractArguments memory _governorContractArguments,
    address _nftContractAddress,
    address _vault
  )
    Governor("GovernorContract")
    GovernorSettings(
      _governorContractArguments._votingDelay, 
      _governorContractArguments._votingPeriod,
      0 // proposal threshold
    )
    GovernorVotes()
    GovernorVotesQuorumFraction(_governorContractArguments._quorumPercentage)
    GovernorTimelockControl()
  {
    nftContractAddress = _nftContractAddress;
    vault = IVault(_vault);
  }

  struct Proposal{
    uint256 propId;
    address[] targets;
    uint256[] values;
    bytes[] calldatas;
    string description;
  }

  mapping(uint256 => Proposal) public allProposals;

  function checkUpkeep(
  bytes calldata checkData
  )
  external
  view
  override
  returns (
    bool upkeepNeeded,
    bytes memory performData
  ){
    uint256 currStage = vault.getCurrentStage(nftContractAddress);
    Proposal memory thisProposal = allProposals[currStage];
    return(uint256(state(thisProposal.propId)) == 5, bytes(""));
  }

  function performUpkeep(
  bytes calldata performData
) external override{
  uint256 currStage = vault.getCurrentStage(nftContractAddress);
  Proposal memory thisProposal = allProposals[currStage];
  bytes32 descriptionHash = keccak256(abi.encodePacked(thisProposal.description));
  execute(thisProposal.targets,thisProposal.values,thisProposal.calldatas,descriptionHash);
}

  function votingDelay()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingDelay();
  }

  function votingPeriod()
    public
    view
    override(IGovernor, GovernorSettings)
    returns (uint256)
  {
    return super.votingPeriod();
  }

  // The following functions are overrides required by Solidity.

  function quorum(uint256 blockNumber)
    public
    view
    override(IGovernor, GovernorVotesQuorumFraction)
    returns (uint256)
  {
    return super.quorum(blockNumber);
  }

  function getVotes(address account, uint256 blockNumber)
    public
    view
    override(IGovernor, Governor)
    returns (uint256)
  {
    return super.getVotes(account, blockNumber);
  }

  function state(uint256 proposalId)
    public
    view
    override(Governor, GovernorTimelockControl)
    returns (ProposalState)
  {
    return super.state(proposalId);
  }

  function propose(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    string memory description
  ) public override(Governor, IGovernor) returns (uint256) {
    uint256 propId = super.propose(targets, values, calldatas, description);
    Proposal memory thisProposal = Proposal(
      propId,
      targets,
      values,
      calldatas,
      description
    );
    uint256 currStage = vault.getCurrentStage(nftContractAddress);
    allProposals[currStage] = thisProposal;
    return propId;
  }

  function proposalThreshold()
    public
    view
    override(Governor, GovernorSettings)
    returns (uint256)
  {
    return super.proposalThreshold();
  }

  function _execute(
    uint256 proposalId,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) {
    super._execute(proposalId, targets, values, calldatas, descriptionHash);
  }

  function _cancel(
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    bytes32 descriptionHash
  ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
    return super._cancel(targets, values, calldatas, descriptionHash);
  }

  function _executor()
    internal
    view
    override(Governor, GovernorTimelockControl)
    returns (address)
  {
    return super._executor();
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(Governor, GovernorTimelockControl)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

}