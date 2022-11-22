// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/token/ERC20/IERC20.sol";
import "./openzeppelin/token/ERC721/IERC721.sol";

// For creating a Gnosis Multisig Wallet
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";

import "./CampaignFactory.sol";

// For Testing
import "forge-std/console.sol";


contract Vault{
    // TODO: Change network accordingly
    // USDC Mainnet
    IERC20 public USDCContract = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    // USDC Goerli
    // IERC20 public USDCContract = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
    
    struct Campaign {
        address nftCreator;
        address nftContractAddress;
        CampaignFactory campaign;
        address multisig;
        uint256 currentStage;
        uint256 totalStages;
        uint128 nftsMinted;
        uint256[] fundsPerStage;
        uint256 currentFunds;
        uint256 totalFundsRequired;
        bool campaignRemoved;
    }

    // allCampaigns maps from the nft contract address to the campaign structure
    mapping(address => Campaign) public allCampaigns;

    // address is timelock which is created when a campaign is created. And it is set to true when we create this timelock. 
    // This is done so that we restrict access to any others other than the timelocks to call functions like releaseFunds, removeCampaign etc
    mapping(address => bool) public timelocks;

    // This mapping is to track who all have claimed their tokens back after the campaign removal
    // The mapping is from - whom(address) => nftcontract address => true/false 
    mapping(address => mapping(address => bool)) public fundsClaimedAfterCampaignRemoval;

    //for Gnosis
    address public immutable masterCopyAddress;
    GnosisSafeProxyFactory public immutable proxyFactory;


    struct ForGovToken {
        string _govTokenName;
        string _govTokenSymbol;
    }

    struct ForGovernor{
        uint256 _quorumPercentage;
        uint256 _votingPeriod;
        uint256 _votingDelay;
    }

    struct MultiSig{
        address[] _signatories;
        uint256 _quorum;
    }

    constructor() {
        proxyFactory = GnosisSafeProxyFactory (0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        masterCopyAddress = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
    }


    struct timelockContractArguments{
        uint256 _minDelay;
        address[] _proposers;
        address[] _executors;
    }

    // setting up a new campaign
    // This returns the campaign address. It is useful for testing.
    function setupCampaign(
        address _nftContractAddress,
        timelockContractArguments memory _timelockContractArguments,
        uint256 _totalStages,
        uint256[] calldata _fundsPerStage,
        uint256 _totalFundsRequired,
        MultiSig calldata _multisig
        ) external returns(address) {
        require(_fundsPerStage.length == _totalStages, "Error! FundsPerStage not matching the no of stages");
        require(_totalStages > 0 && _totalFundsRequired > 0, "totalStages or TotalFundsRequired cannot be 0");

        // TODO: Remove hardcoded values
        CampaignFactory newCampaign = new CampaignFactory(
            _nftContractAddress,
            _timelockContractArguments,
            5, 10, 10, address(this)
        );
        // campaignFactory is the timelock itself
        timelocks[address(newCampaign)] = true;

        //creating multisig
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _multisig._signatories,
            _multisig._quorum,
            address(0x0),
            new bytes(0),
            address(0x0),
            address(0x0),
            0,
            address(0x0)
        );
        address newMultisig = address(proxyFactory.createProxy(masterCopyAddress, initializer));
        require(newMultisig != address(0), "Safe deployment failed");
        
        //Storing this particular campaign
        Campaign memory newCampaignStruct = Campaign(
            msg.sender,
            _nftContractAddress,
            newCampaign,
            newMultisig,
            1,
            _totalStages,
            0,
            _fundsPerStage,
            0,
            _totalFundsRequired,
            false
        );
        allCampaigns[_nftContractAddress] = newCampaignStruct;
        return address(newCampaign);
    }

    function getCampaign(address  _nftContractAddress) public view returns(Campaign memory){
        return allCampaigns[_nftContractAddress];
    }

    function releaseFunds(address _nftContractAddress) external  {
        require(timelocks[msg.sender] == true, "You are not authorized");
        Campaign memory thisCampaign = allCampaigns[_nftContractAddress];
        USDCContract.transfer(thisCampaign.multisig, thisCampaign.fundsPerStage[thisCampaign.currentStage - 1]);
        allCampaigns[_nftContractAddress].currentStage++;
    }

    function removeCampaign(address _nftContractAddress) external {
        require(timelocks[msg.sender] == true, "You are not authorized");
        allCampaigns[_nftContractAddress].campaignRemoved = true;
    }

    //to withdraw funds when the campaign is removed
    function withdrawFundsAfterCampaignRemoval(address _nftContractAddress) external {
        IERC721 nftContract = IERC721(_nftContractAddress);
        require(nftContract.balanceOf(msg.sender) > 0, "You are not Authorized");
        require(allCampaigns[_nftContractAddress].campaignRemoved == true, "the campaign is not removed yet");
        require(fundsClaimedAfterCampaignRemoval[msg.sender][_nftContractAddress] = false, "You have already claimed once");
        fundsClaimedAfterCampaignRemoval[msg.sender][_nftContractAddress] = true;
        uint256 totalNftsOwnedByUser = nftContract.balanceOf(msg.sender);
        uint256 totalAmountInUSDC = allCampaigns[_nftContractAddress].currentFunds;
        uint256 withdrawAmount = (totalAmountInUSDC*totalNftsOwnedByUser)/allCampaigns[_nftContractAddress].nftsMinted;
        USDCContract.transfer(msg.sender, withdrawAmount);
    }


    function getCurrentStage(address _nftContractAddress) external view returns(uint256){
        return allCampaigns[_nftContractAddress].currentStage;
    }

     function supplyFundsToCampaign(uint256 _amount) external{
        require(msg.sender == allCampaigns[msg.sender].nftContractAddress, "You are not authorized");
        allCampaigns[msg.sender].currentFunds += _amount;
        // incrementing the no of minted nfts
        allCampaigns[msg.sender].nftsMinted++;
    }

    function mintGovernanceTokens(address _to, uint256 _amount) external{
        require(msg.sender == allCampaigns[msg.sender].nftContractAddress, "You are not authorized");
        // mint some governance token to the sender
        CampaignFactory campaignFactory = allCampaigns[msg.sender].campaign;
        uint256 rate = _amount * 10 ** 12;
        campaignFactory.mint(_to, rate);
    }

}