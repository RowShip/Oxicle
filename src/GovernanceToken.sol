// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/token/ERC20/extensions/ERC20Votes.sol";
import "./openzeppelin/access/Ownable.sol";

contract GovernanceToken is ERC20Votes, Ownable {

  constructor(string memory _name, string memory _symbol) ERC20Permit("GovernanceToken")  ERC20(_name, _symbol) {
  }

  function mint(address _to, uint256 _amount) external onlyOwner{
    _mint(_to, _amount);
  }

  // Overrides required by Solidity.

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20Votes) {
    super._afterTokenTransfer(from, to, amount);
  }

  function _mint(address to, uint256 amount) internal virtual override(ERC20Votes) {
    super._mint(to, amount);
  }

  function _burn(address account, uint256 amount) internal virtual override(ERC20Votes) {
    super._burn(account, amount);
  }
}