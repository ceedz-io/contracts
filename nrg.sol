// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract NRG is ERC20 {
    uint8 private _decimals = 0;
    mapping(address => bool) private _minter;
    /**
     * @dev Sets the values for {initialMintAddress}, {initialSupply} and {dec}.
     *
     */
    constructor() ERC20("eNeRGy", "NRG") {
        _decimals = 18;
        _minter[msg.sender] = true;
    }
    
    
    /**
    * @dev returns how many decimals. 
    */
    function decimals() public override view returns (uint8){
         return _decimals;
    }
    
    function addMinter(address minter) public {
        require(_minter[msg.sender],"Not allowed to add minter");
        _minter[minter] = true;
    }
    
    function removeMinter() public {
        _minter[msg.sender] = false;
    }
    
    function mint(address to, uint256 amount) public{
        require(_minter[msg.sender],"Not a minter");
        _mint(to, amount);
    }
}