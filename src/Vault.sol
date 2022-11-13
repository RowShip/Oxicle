// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./openzeppelin/token/ERC20/IERC20.sol";

//For creating a Gnosis Multisig Wallet
import "safe-contracts/proxies/GnosisSafeProxyFactory.sol";

import "./DeployNft.sol";
import "./CampaignFactory.sol";


contract Vault{
    uint256 campaignCount;
    //TODO: Change network accordingly
    //USDC Mainnet
    IERC20 public USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    //USDC Goerli
    // IERC20 public USDC = IERC20(0xA2025B15a1757311bfD68cb14eaeFCc237AF5b43);
    
    struct Campaign {
        address nftCreator;
        NftContract nft;
        GovernanceToken govToken;
        TimeLock timelock;
        GovernorContract governor;
        address multisig;
        uint256 currentStage;
        uint256 totalStages;
        uint256[] fundsPerStage;
        uint256 currentFunds;
        uint256 totalFundsRequired;
        bool campaignRemoved;
    }
    mapping(uint256 => Campaign) public allCampaigns;
    mapping(address => bool) public timelocks;
    mapping(address => bool) public nftContracts;
    
    mapping(address => mapping(address => bool)) public fundsClaimedAfterCampaignRemoval;

    //for Gnosis
    address public immutable masterCopyAddress;
    GnosisSafeProxyFactory public immutable proxyFactory;


    struct ForGovToken {
        string _govTokenName;
        string _govTokenSymbol;
    }

    struct ForNft{
        string _nftName;
        string _nftSymbol;
        uint256 _nftMaxSupply;
        uint256 _priceInUSDC;
        string _setBaseURI;
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
        proxyFactory = GnosisSafeProxyFactory(0xa6B71E26C5e0845f74c812102Ca7114b6a896AB2);
        masterCopyAddress = 0x3E5c63644E683549055b9Be8653de26E0B4CD36E;
    }

    // Precompute the contract address of Timelock and GovernanceToken contract
    // TODO: should precomuping feature be here or in a library?
    function precomputeAddressOfTimelock() private view returns(address) {
        bytes memory creationCode = type(TimeLock).creationCode;
        // TODO: pass in correct arguements here for TimeLock instead of 1 ,[] ,[]
        bytes memory bytecode = abi.encodePacked(creationCode, abi.encode(1, [], []));

        // TODO: possibly change salt to other number. address(this) is address of deployer
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), 777, keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }

    function precomputeAddressOfGovernanceToken() private view returns(address) {
        bytes memory creationCode = type(GovernanceToken).creationCode;
        // TODO: pass in correct arguements here for GovernanceToken
        bytes memory bytecode = abi.encodePacked(creationCode, abi.encode("SampleName", "SampleSymol"));

        // TODO: possibly change salt to other number. address(this) is address of deployer
        bytes32 hash = keccak256(
            abi.encodePacked(
                bytes1(0xff), address(this), 777, keccak256(bytecode)
            )
        );
        return address(uint160(uint(hash)));
    }


    //setting up a new campaign
    function setupCampaign(
        ForGovToken calldata _govTok,
        ForNft calldata _nftCont,
        uint256 _minDelay,
        uint256 _totalStages,
        uint256[] calldata _fundsPerStage,
        uint256 _totalFundsRequired,
        ForGovernor calldata _GovernorCont,
        MultiSig calldata _multisig
        ) external {
        require(_fundsPerStage.length == _totalStages, "Error! FundsPerStage not matching the no of stages");
        campaignCount++;
        
        //create and deploy Governance Token contract
        // GovernanceToken newGovToken = DeployGovToken.createGovTokenContract(_govTok);

        // //create and deploy Timelock contract
        // TimeLock newTimelock = DeployTimelock.createTimelockContract(_minDelay);
        // timelocks[address(newTimelock)] = true;
    
        // //create and deploy Governor Contract
        // GovernorContract newGovernor = DeployGovernor.createGovernorContract(newGovToken, newTimelock, _GovernorCont, campaignCount, address(this));
        
        // TODO: pass the parameters passed in this function when declaring Campaign Factory
        address timeLockContractAddress = precomputeAddressOfTimelock();
        address governanceTokenContractAddress  = precomputeAddressOfGovernanceToken();

        // TODO: Pass in correct arguments 
        CampaignFactory newCampaign = CampaignFactory(
            _minDelay,
            [],
            [],
            governanceTokenContractAddress,
            timeLockContractAddress,
            0, 0, 0, 0, address(0)
        );

        //create and deploy nft contract
        NftContract newNftContract = DeployNft.createNftContract(campaignCount,_nftCont,address(this),address(newGovToken));
        nftContracts[address(newNftContract)] = true;

        //creating multisig
        // TODO: 
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

        // TODO: grant roles in timelock
        newTimelock.grantRole(newTimelock.PROPOSER_ROLE(), address(newGovernor));
        newTimelock.grantRole(newTimelock.EXECUTOR_ROLE(), address(0));
        //Revoking role here
        newTimelock.revokeRole(newTimelock.TIMELOCK_ADMIN_ROLE(), msg.sender);
        //making nftContract the owner of GovernanceToken Contract
        newGovToken.transferOwnership(address(newNftContract));
        //making NftCreator the owner of nftContract
        newNftContract.transferOwnership(msg.sender);

        // TODO: Create new campaign using campaign factory
        //Storing this particular campaign
        Campaign memory newCampaign = Campaign(
            msg.sender,
            newNftContract,
            newGovToken,
            newTimelock,
            newGovernor,
            newMultisig,
            1,
            _totalStages,
            _fundsPerStage,
            0,
            _totalFundsRequired,
            false
        );
        allCampaigns[campaignCount] = newCampaign;
    }

    function releaseFunds(uint256 _campaignId) external  {
        require(timelocks[msg.sender] == true, "You are not authorized");
        Campaign memory thisCampaign = allCampaigns[_campaignId];
        USDC.transfer(thisCampaign.multisig, thisCampaign.fundsPerStage[thisCampaign.currentStage - 1]);
        allCampaigns[_campaignId].currentStage++;
    }

    function removeCampaign(uint256 _campaignId) external {
        require(timelocks[msg.sender] == true, "You are not authorized");
        allCampaigns[_campaignId].campaignRemoved = true;
    }

    //to withdraw funds when the campaign is removed
    function withdrawFundsAfterCampaignRemoval(address _nftContract) external {
        NftContract nftContract = NftContract(_nftContract);
        uint256 thisCampaignId = nftContract.campaignId();
        require(nftContract.balanceOf(msg.sender) > 0, "You are not Authorized");
        require(allCampaigns[thisCampaignId].campaignRemoved == true, "the campaign is not removed yet");
        require(fundsClaimedAfterCampaignRemoval[msg.sender][_nftContract] = false, "You have already claimed once");
        fundsClaimedAfterCampaignRemoval[msg.sender][_nftContract] = true;
        uint256 totalNftsOwnedByUser = nftContract.balanceOf(msg.sender);
        uint256 totalAmountInUSDC = allCampaigns[thisCampaignId].currentFunds;
        uint256 withdrawAmount = (totalAmountInUSDC*totalNftsOwnedByUser)/nftContract.totalSupply();
        USDC.transfer(msg.sender, withdrawAmount);
    }


    function getCurrentStage(uint256 _campaignId) external view returns(uint256){
        return allCampaigns[_campaignId].currentStage;
    }

    function setCurrentFunds(uint256 _campaignId, uint256 _amount) external{
        require(nftContracts[msg.sender] == true, "You are not authorized");
        allCampaigns[_campaignId].currentFunds += _amount;
    }

}
