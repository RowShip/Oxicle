// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../openzeppelin/token/ERC721/ERC721.sol";
import "../openzeppelin/utils/Counters.sol";

// This contract needs to be imported for this NFT contract to be compatible with our protocol.
import "./ForceSend.sol";

contract NFTContract is ERC721, ForceSend {
    uint256 pricePerNft = 20000000; //20USDC
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    // TODO: Passing vaultAddress. ONLY FOR TESTING PURPOSE
    constructor(address _vaultAddress) ERC721("MyToken", "MTK") ForceSend(_vaultAddress){}

    // The contract will just need to add the sendToVault modifier which forces the USDC to be sent from the user to the Vault on each mint
    // Since we are using USDC this nft contract address should be approved in the USDC contract by the user.
    // Approve(Nftcontractaddress, pricePerNft) can be done on the frontend.
    function safeMint() public sendToVault(pricePerNft) {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }
}