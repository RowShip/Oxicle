// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/token/ERC721/ERC721.sol";
import "./openzeppelin/access/Ownable.sol";
import "./openzeppelin/utils/Counters.sol";
import "./openzeppelin/token/ERC20/IERC20.sol";

interface IGov {
    function mint(address _to, uint256 _amount) external;
}

interface VaultInterface{
    function setCurrentFunds(uint256 _campaignId, uint256 _amountInUSDC) external;
}

contract NftContract is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IERC20 public USDC;
    IGov public governanceToken;
    VaultInterface public vaultContract;
    uint256 public priceInUSDC;
    uint256 public maxSupply;
    string public baseURI;
    address public vault;
    uint256 public campaignId;

    
    

    constructor(
        uint256 _campaignId,
        string memory _name,
        string memory _symbol,
        uint256 _maxSupply,
        uint256 _priceInUSDC,
        string memory _setBaseURI,
        address _governanceToken,
        address _vault
    ) ERC721(_name, _symbol) {
        campaignId = _campaignId;
        maxSupply = _maxSupply;
        priceInUSDC = _priceInUSDC;
        baseURI = _setBaseURI;
        //TODO: Change Accordingly
        //Mainnet
        USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        //Goerli
        // USDC = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
        //OR Goerli
        // USDC = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        governanceToken = IGov(_governanceToken);
        vault = _vault;
        vaultContract = VaultInterface(_vault);
        
    }

    
    //the approve function needs to be called before calling the below func.
    function safeMint() external {
        require(_tokenIdCounter.current() < maxSupply, "Max supply exceeded!");
        //transfer USDC from sender to this the vault contract
        USDC.transferFrom(msg.sender, vault, priceInUSDC);
        vaultContract.setCurrentFunds(campaignId, priceInUSDC);
        //mint some governance token to the sender
        uint256 rate = priceInUSDC * 10 ** 12;
        governanceToken.mint(msg.sender, rate);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter.current();
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    

    
}
