// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "hardhat/console.sol";

contract NFT1155 is ERC1155, Ownable, ERC1155Supply {
    constructor() ERC1155("") {}

    mapping(uint256 => string) internal _tokenURIs;
    mapping(uint256 => MarketItem) private idToMarketItem;
    Counters.Counter private _itemsSold;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //To chnage the URL String after the contract is deployed
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function mintToken(
        string memory tokenURI,
        uint256 amount,
        uint256 price
    ) public returns (uint256) {
        uint256 newItemId = _tokenIds.current();
        _mint(address(this), newItemId, amount, "");
        _setTokenUri(newItemId, tokenURI);
        //createMarketItem(newItemId, price, amount);
        _tokenIds.increment();
        return newItemId;
    }

    function createMarketItem(
        uint256 tokenId,
        uint256 price,
        uint256 amount
    ) public{
        require(price > 0, "Price must be at least 1 wei");
        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        setApprovalForAll(address(this), true);

        safeTransferFrom(msg.sender, address(this), tokenId, amount, "");

        emit MarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /* Creates the sale of a marketplace item */
    /* Transfers ownership of the item, as well as funds between parties */
    function createMarketSale(uint256 tokenId, uint256 amount) public payable {
        address seller = idToMarketItem[tokenId].seller;
        idToMarketItem[tokenId].owner = payable(msg.sender);
        idToMarketItem[tokenId].sold = true;
        idToMarketItem[tokenId].seller = payable(address(0));

        _itemsSold.increment();

        safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        setApprovalForAll(address(this), true);
        // payable(owner).transfer(listingPrice);
        payable(seller).transfer(msg.value);
    }
}