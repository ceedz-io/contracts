// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./nrg.sol";
import "./nectar.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";

contract SeedContract is ERC721Enumerable {
    using BytesLib for bytes;
    string private _baseUri;
    NRG private _nrg;
    Nectar private _nectar;
    
    mapping(uint256 => uint256) private _plantDate;
    mapping(uint256 => uint256) private _numPollinations;
    
    struct Seed {
        uint256 idx;
        uint256 parentIdx;
        uint256 daysSincePlantDate;
        uint256 timeToPollination;  
        uint256 pollinationWindow; 
        uint256 maturationWindow;
    }

    //event Pollinate(address indexed from, address indexed to, uint256 indexed tokenId);
    
    constructor() ERC721("CEED", "CEED"){
       //uint256 genesis = 0x0e00ff;
       uint256 genesis = 0x0000000100000002090e07ff;
       //uint256 genesis = 0xffee222222221111111111111111111111111111111111111111111111111111
       _safeMint(msg.sender, genesis);
       _nrg = new NRG();
       _nectar = new Nectar(address(_nrg));
       _nrg.addMinter(address(_nectar));
    }
    
    function nrg() public view returns (NRG){
        return _nrg;
    }
    
    function numSeeds(uint256 tokenId) public view returns (uint256){
        return _numPollinations[tokenId];
        
    }
    
    function plant(uint256 tokenId) public {
        require(ownerOf(tokenId)==msg.sender);
        _plantDate[tokenId] = block.timestamp;
    }
    
    function potentialNrgYield(uint256 tokenId) public view returns (uint256){
        Seed memory seed = info(tokenId);
        uint256 _days = seed.timeToPollination + seed.pollinationWindow + seed.maturationWindow/2;
        uint256 yield = _days * 1e16;
        uint256 seedLoss = _numPollinations[tokenId]*1e14;
        if(seedLoss>=yield) return 0;
        return yield-seedLoss;
    }
    
    function nrgYield(uint256 tokenId) public view returns (uint256){
        Seed memory seed = info(tokenId);
        if(seed.daysSincePlantDate<seed.timeToPollination + seed.pollinationWindow) return 0;
        uint256 timeToMaturation = seed.timeToPollination + seed.pollinationWindow;
        uint256 _days = timeToMaturation;
        if(seed.daysSincePlantDate<_days + seed.maturationWindow/2){
            _days = seed.daysSincePlantDate;
        } else if(seed.daysSincePlantDate<_days + seed.maturationWindow){
            _days += seed.maturationWindow/2;
        } else {
            _days += seed.maturationWindow/2;
            uint256 decay = (seed.daysSincePlantDate - timeToMaturation - seed.maturationWindow) * 10;
            if(decay>=_days){
                _days = 0;
            } else {
                _days -= decay;
            }
        }
        uint256 yield = _days * 1e16;
        uint256 seedLoss = _numPollinations[tokenId]*1e14;
        if(seedLoss>=yield) return 0;
        return yield-seedLoss;
    }
    
    /*
    function seed(uint256 tokenId) public {
        uint32 x = 123;
    }
    */
    
    /* need to put this in a struct */
    
    function info(uint256 tokenId) public view returns (Seed memory){
        require(ownerOf(tokenId)!=address(0));
        uint256 daysSincePlantDate = 0;
        if(_plantDate[tokenId]>0){
            daysSincePlantDate = (block.timestamp - _plantDate[tokenId])/(1 days);
        }
        return Seed({
            idx: uint256(_bytesAt(tokenId,24,4).toUint32(0)),
            parentIdx: uint256(_bytesAt(tokenId,20,4).toUint32(0)),
            daysSincePlantDate: daysSincePlantDate,
            timeToPollination: uint256(_bytesAt(tokenId,28,1).toUint8(0)),
            pollinationWindow: uint256(_bytesAt(tokenId,29,1).toUint8(0)),
            maturationWindow: uint256(_bytesAt(tokenId,30,1).toUint8(0))
        });
    }
    
    function maxSeeds(uint256 tokenId) public view returns (uint256){
        require(ownerOf(tokenId)!=address(0));
        return uint256(_bytesAt(tokenId,31,1).toUint8(0));
    }
 
    
    function pollinate(uint256 tokenId) public {
        require(ownerOf(tokenId)!=address(0),"token does not exist");
        require(_numPollinations[tokenId]<maxSeeds(tokenId));
        _numPollinations[tokenId]++;
        _nectar.mint(msg.sender,1e14);
    }
    
    /*
    function mint(address to, uint256 tokenId) public onlyOwner{
        _safeMint(to, tokenId);
    }
    */
    function _bytesAt(uint256 tokenId, uint256 start, uint256 ln) public pure returns (bytes memory){
        bytes memory b = _tokenIdToBytes(tokenId);
        return b.slice(start,ln);
    }
    
    function _toBytes(uint8 n) public pure returns (bytes memory){
        return abi.encodePacked(n);
    }
    
    function _tokenIdToBytes(uint256 tokenId) public pure returns (bytes memory){
        return abi.encodePacked(tokenId);
    }
    
}