//SPDX-License-Identifier:MIT

pragma solidity ^0.8.8;

//imports
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";

//errors
error MallMart_NFT__PriceMustBeAboveZero();
error MallMart_NFT__PriceMustbeEqualToListingPrice();
error MallMart_NFT__OnlyNFTOwnerCanResale();
error MallMart_NFT__InsufficientValueToProcessPurchase();

contract NFT_MallMart is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;
    address payable owner;
    uint256 listingPrice;

    mapping(uint256 => MarketItem) private idMarketItem;
    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //events
    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can access to update the NFT price");
        _;
    }

    modifier OnlyListingPrice() {
        if (msg.value != listingPrice) {
            revert MallMart_NFT__PriceMustbeEqualToListingPrice();
        }
        _;
    }

    constructor() ERC721("NFT Token", "MYNFT") {
        owner == payable(msg.sender);
        listingPrice = 0.00025 ether;
    }

    function updateListingPrice(uint _listPrice) public payable onlyOwner {
        listingPrice = _listPrice;
    }

    function getlistingPrice() public view returns (uint256) {
        return listingPrice;
    }

    function createToken(string memory tokenURI, uint256 price) public payable returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    function createMarketItem(uint256 tokenid, uint256 price) private OnlyListingPrice {
        if (price <= 0) {
            revert MallMart_NFT__PriceMustBeAboveZero();
        }

        idMarketItem[tokenid] = MarketItem(
            tokenid,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        _transfer(msg.sender, address(this), tokenid);
        emit idMarketItemCreated(tokenid, msg.sender, address(this), price, false);
    }

    function reSaleToken(uint256 tokenid, uint256 price) public payable OnlyListingPrice {
        if (idMarketItem[tokenid].owner != msg.sender) {
            revert MallMart_NFT__OnlyNFTOwnerCanResale();
        }
        idMarketItem[tokenid].sold = false;
        idMarketItem[tokenid].price = price;
        idMarketItem[tokenid].seller = payable(msg.sender);
        idMarketItem[tokenid].owner = payable(address(this));
        _itemsSold.decrement();
        _transfer(msg.sender, address(this), tokenid);
    }

    function BuyToken(uint256 tokenid) public payable {
        uint256 price = idMarketItem[tokenid].price;
        if (msg.value != price) {
            revert MallMart_NFT__InsufficientValueToProcessPurchase();
        }
        idMarketItem[tokenid].owner = payable(msg.sender);
        idMarketItem[tokenid].sold = true;
        idMarketItem[tokenid].owner = payable(address(0));
        _itemsSold.increment();

        _transfer(address(this), msg.sender, tokenid);
        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenid].seller).transfer(msg.value);
    }

    function fetchListedNFT() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIds.current();
        uint256 unSoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint256 currentIndex = 0;

        MarketItem[] memory ItemUnsold = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentID = i + 1;
                MarketItem storage currentItem = idMarketItem[currentID];
                ItemUnsold[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return ItemUnsold;
    }

    function fetchMyNft() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory ItemBought = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                ItemBought[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return ItemBought;
    }

    function FetchItemListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory ItemListed = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                ItemListed[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return ItemListed;
    }
}
