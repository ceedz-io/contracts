// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import './nrg.sol';

contract Nectar is ERC20 {
    mapping(address => uint256) private _balances;
    uint8 private _decimals = 0;
    address private _owner;
    NRG private immutable _nrg;
    /**
     * @dev Sets the values for {initialMintAddress}, {initialSupply} and {dec}.
     *
     */
    constructor(address nrgAddress) ERC20("Nectar", "NCTR") {
        _decimals = 18;
        _owner = msg.sender;
        _nrg = NRG(nrgAddress);
    }
    
    /**
    * @dev returns how many decimals. 
    */
    function decimals() public override view returns (uint8){
         return _decimals;
    }
    
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }
    
    function mint(address to, uint256 amount) public{
        require(msg.sender==_owner);
        _mint(to, amount);
    }
    
    function consume(uint256 amount) public{
        uint256 bal = _balances[msg.sender];
        require(amount>0 && bal>=amount,"Inavild amount");
        _balances[msg.sender] -= amount;
        _nrg.mint(msg.sender, bal*10);
    }
}