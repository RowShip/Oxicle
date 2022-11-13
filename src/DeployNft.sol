// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./NftContract.sol";
import "./Vault.sol";


library DeployNft{

    function createNftContract(uint256 _campaignId, Vault.ForNft calldata _nftCont,address _vault, address _newGovToken) public returns(NftContract){
        NftContract newNftContract = new NftContract(
            _campaignId,
            _nftCont._nftName,
            _nftCont._nftSymbol,
            _nftCont._nftMaxSupply,
            _nftCont._priceInUSDC,
            _nftCont._setBaseURI,
            _newGovToken,
            _vault
        );
        return newNftContract;
    }
}