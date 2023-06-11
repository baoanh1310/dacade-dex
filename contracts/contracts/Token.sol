// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IcebearToken is ERC20 {

    event Faucet(address indexed minter, uint256 amount);

    uint256 public DEFAULT_MINT_AMOUNT = 1000;

    constructor() ERC20("Icebear Token", "ICB") {
    }

    // faucet 1000 ICB tokens
    function faucet() public {
        uint256 amount = DEFAULT_MINT_AMOUNT * (10 ** decimals());
        _mint(msg.sender, amount);
        emit Faucet(msg.sender, DEFAULT_MINT_AMOUNT);
    }
}