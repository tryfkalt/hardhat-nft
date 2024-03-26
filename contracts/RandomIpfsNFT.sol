// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error RandomIpfsNft__AlreadyInitialized();
error RandomIpfsNft__NeedMoreETHSent();
error RandomIpfsNft__RangeOutOfBounds();
error RandomIpfsNft__TransferFailed();

contract RandomIpfsNFT is ERC721URIStorage, VRFConsumerBaseV2, Ownable {
  // when we mint an nft we will trigger a Chainlink VRF call to get us a random number
  // using that number we will get a random nft

  // users have to pay to mint an NFT
  // the owner of the contract can withdraw the ETH

  // Type Declarations
  enum Breed {
    PUG,
    SHIBA_INU,
    ST_BERNARD
  }

  // Chainlink VRF variables
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  uint64 private immutable i_subscriptionId;
  bytes32 private immutable i_gasLane;
  uint32 private immutable i_callbackGasLimit;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private constant NUM_WORDS = 1;

  // VRF Helpers
  mapping(uint256 => address) public s_requestIdToSender;

  // NFT Helpers
  uint256 public s_tokenCounter;
  uint256 internal constant MAX_CHANCE_VALUE = 100;
  string[] internal s_dogTokenUris; // list of uris for the different dogs (json files on ipfs)
  uint256 internal i_mintFee;

  // Events
  event NftRequested(uint256 indexed requestId, address indexed requester);
  event NftMinted(uint256 indexed tokenId, Breed indexed breed, address indexed minter);

  constructor(
    address vrfCoordinatorV2,
    uint64 subscriptionId,
    bytes32 gasLane, // keyHash
    uint256 mintFee,
    uint32 callbackGasLimit,
    string[3] memory dogTokenUris
  ) VRFConsumerBaseV2(vrfCoordinatorV2) ERC721("Random IPFS NFT", "RIN") {
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_mintFee = mintFee;
    i_callbackGasLimit = callbackGasLimit;
    // _initializeContract(dogTokenUris);
    s_tokenCounter = 0;
  }

  function requestNft() public payable returns (uint256 requestId) {
    if (msg.value < i_mintFee) {
      revert RandomIpfsNft__NeedMoreETHSent();
    }
    requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane,
      i_subscriptionId,
      REQUEST_CONFIRMATIONS,
      i_callbackGasLimit,
      NUM_WORDS
    );

    s_requestIdToSender[requestId] = msg.sender;
    emit NftRequested(requestId, msg.sender);
  }

  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    address dogOwner = s_requestIdToSender[requestId];
    // if we didn't create a mapping of requestId to sender, then when the mint function is called
    // the msg.sender is the Chainlink node and not the requester. Now with the mapping, the minted nft is given to the requester
    uint256 tokenId = s_tokenCounter;
    uint256 moddedRng = randomWords[0] % MAX_CHANCE_VALUE;
    // 0-99 random number
    // e.g 7 --> 1st dog
    // e.g 35 --> 3nd dog
    // e.g 99 --> 3rd dog
    // e.g 12 --> 2rd dog
    // so if [0-10] --> 1st dog [11-30] --> 2nd dog [31-100] --> 3rd dog
    Breed dogBreed = getBreedFromModdedRng(moddedRng);
    s_tokenCounter += 1;
    _safeMint(dogOwner, tokenId);
    _setTokenURI(tokenId, s_dogTokenUris[uint256(dogBreed)]);
    emit NftMinted(tokenId, dogBreed, dogOwner);
  }

  function withdraw() public onlyOwner {
    uint256 amount = address(this).balance; // the balance of the contract
    (bool success, ) = payable(owner()).call{value: amount}("");
    if (!success) {
      revert RandomIpfsNft__TransferFailed();
    }
  }

  function getBreedFromModdedRng(uint256 moddedRng) public pure returns (Breed) {
    uint256 cumulativeSum = 0;
    uint256[3] memory chanceArray = getChanceArray();
    for (uint256 i = 0; i < chanceArray.length; i++) {
      cumulativeSum += chanceArray[i];
      if (moddedRng >= cumulativeSum && moddedRng < cumulativeSum + chanceArray[i]) {
        return Breed(i);
      }
      cumulativeSum += chanceArray[i];
    }
    revert RandomIpfsNft__RangeOutOfBounds();
  }

  // this array represents the different chances of different NFTs
  function getChanceArray() public pure returns (uint256[3] memory) {
    return [10, 30, MAX_CHANCE_VALUE];
    // FIRST DOG 10% CHANCE
    // SECOND DOG 20% CHANCE (30-10)
    // THIRD DOG 60% CHANCE (100-30-10)
  }

  function getMintFee() public view returns (uint256) {
    return i_mintFee;
  }

  function getDogTokenUris(uint256 index) public view returns (string memory) {
    return s_dogTokenUris[index];
  }

  function getTokenCounter() public view returns (uint256) {
    return s_tokenCounter;
  }
}
