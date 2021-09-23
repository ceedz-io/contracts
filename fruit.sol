// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./nrg.sol";
import "./seed.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract Fruit is ERC721Enumerable {
    using BytesLib for bytes;
    NRG immutable private _nrg;
    SeedContract immutable private _seed;
    address private _owner;
    mapping(uint256 => address) private _seedOwner;
    mapping(uint256 => uint256) private _seedId;
    
    constructor(address nrg) ERC721("Fruit", "FRT"){
        _owner = msg.sender;
       _nrg = NRG(nrg);
       _seed = SeedContract(msg.sender);
    }
    
    function mint(uint256 seedId, address to) public {
        require(msg.sender==_owner,"Not allowed to mint");
        _seedOwner[seedId] = to;
        uint256 tokenId = _getTokenId(seedId);
        _seedId[tokenId] = seedId;
        _safeMint(to, tokenId);
    }
    
    function fruitType(uint256 tokenId) public pure returns (uint256){
        bytes memory fruitIDBytes = abi.encodePacked(tokenId);
        bytes memory _fruitType = fruitIDBytes.slice(28,4);
        return uint256(_fruitType.toUint64(0));
    }
    
    function info(uint256 tokenId) public view returns (SeedContract.Seed memory){
        return _seed.info(_seedId[tokenId]);
    }
    
    function nrgYield(uint256 tokenId) public view returns (uint256){
        return _seed.nrgYield(_seedId[tokenId]);
    }
    
    function consume(uint256 tokenId) public {
        uint256 seedId = _seedId[tokenId];
        require(_seedOwner[seedId]==msg.sender);
        _seedOwner[seedId] = address(0); //prevent reentry attack;
        uint256 yield = nrgYield(tokenId);
        _seedId[tokenId] = 0;
        //transfer the seedId
        _seed.transferFrom(address(this),msg.sender,seedId);
        _nrg.mint(msg.sender,yield);
        _burn(tokenId);
    }
    
    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.transferFrom(from,to,tokenId);
        _seedOwner[_seedId[tokenId]] = to;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        super.safeTransferFrom(from, to, tokenId, "");
        _seedOwner[_seedId[tokenId]] = to;
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        super.safeTransferFrom(from, to, tokenId, _data);
        _seedOwner[_seedId[tokenId]] = to;
    }
    
    function _getTokenId(uint256 seedId) private pure returns(uint256){
        bytes memory seedIdBytes = abi.encodePacked(seedId);
        bytes memory fruitIdBytes = seedIdBytes.slice(24,8);
        return uint256(fruitIdBytes.toUint128(0));
    }

    
}