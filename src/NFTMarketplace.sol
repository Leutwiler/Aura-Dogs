// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "../lib/openzeppelin-contracts/contracts/utils/Counters.sol";

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    Counters.Counter private _itemsSold;

    uint256 listingPrice = 0.025 ether;
    address payable owner;

    mapping(uint256 => MarketItem) private idToMarketItem;

    struct MarketItem {
        uint256 tokenId;
        uint256 price;
        address payable seller;
        address payable owner;
        bool sold;
    }

    event MarketItemCreated (
        uint256 indexed tokenId,
        uint256 price,
        address seller,
        address owner,
        bool sold
    );

    constructor() ERC721("Aura Dogs", "WOOF") {
        owner = payable(msg.sender);
    }

    function createToken(string memory _tokenURI, uint256 _price) public payable returns (uint) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _tokenURI);
        createMarketItem(newTokenId, _price);
        return newTokenId;
    }

    function createMarketItem(uint256 _tokenId, uint256 _price) private {
        require(_price > 0, "Price can't be zero");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idToMarketItem[_tokenId] =  MarketItem(
            _tokenId,
            _price,
            payable(msg.sender),
            payable(address(this)),
            false
        );

        _transfer(msg.sender, address(this), _tokenId);

        emit MarketItemCreated(
            _tokenId,
            _price,
            msg.sender,
            address(this),
            false
        );
    }

    function resellToken(uint256 _tokenId, uint256 _price) public payable {
        require(idToMarketItem[_tokenId].owner == msg.sender, "You're not the owner");
        require(msg.value == listingPrice, "Price must be equal to listing price");

        idToMarketItem[_tokenId].sold = false;
        idToMarketItem[_tokenId].price = _price;
        idToMarketItem[_tokenId].seller = payable(msg.sender);
        idToMarketItem[_tokenId].owner = payable(address(this));
        _itemsSold.decrement();

        _transfer(msg.sender, address(this), _tokenId);
    }

    function buyToken(uint256 _tokenId) public payable {
        uint price = idToMarketItem[_tokenId].price;
        require(msg.value == price, "Please submit the asking price");
        address seller = idToMarketItem[_tokenId].seller;

        idToMarketItem[_tokenId].owner = payable(msg.sender);
        idToMarketItem[_tokenId].sold = true;
        idToMarketItem[_tokenId].seller = payable(address(0));
        _itemsSold.increment();
        _transfer(address(this), msg.sender, _tokenId);

        (bool success,) = payable(owner).call{value: listingPrice}("");
        require(success, "Failed to send listing price");

        (bool sent,) = payable(seller).call{value: msg.value}("");
        require(sent, "Failed to send value");

    }

    // Returns all unsold market items
    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _tokenIds.current();
        uint unsoldItemCount = _tokenIds.current() - _itemsSold.current();
        uint currentIndex;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(this)) {
            uint currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex++;
            }
        }
        return items;
    }

    // Returns only items that a user has purchased
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount;
        uint currentIndex;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
            itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
            uint currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex++;
            }
        }
        return items;
    }

    // Returns only items a user has listed
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint totalItemCount = _tokenIds.current();
        uint itemCount;
        uint currentIndex;

        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
            itemCount++;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
            uint currentId = i + 1;
            MarketItem storage currentItem = idToMarketItem[currentId];
            items[currentIndex] = currentItem;
            currentIndex++;
            }
        }
        return items;
    }

    function updateListingPrice(uint _listingPrice) public payable {
        require(owner == msg.sender, "Only marketplace owner can update listing price");
        listingPrice = _listingPrice;
    }

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    // function burnAndRedeem(uint _itemId) public nonReentrant {
    //     require(msg.sender == idToMarketItem[_itemId].owner, "You are not the owner");
    //     uint tokenId = idToMarketItem[_itemId].tokenId;
    //     _burn(tokenId); // Or _burn(_itemId)
        
        
    //     // Test if it really burns
    //     // Test if it doesn't compromise fetch functions
    //     // Create mint
    // }
}