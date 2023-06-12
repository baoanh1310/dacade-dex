// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract IcebearToken is ERC20 {

    /**
     * @dev Event emitted when the faucet function mints tokens to an address.
     * @param minter The address of the account that minted the tokens.
     * @param amount The amount of tokens minted.
     */
    event Faucet(address indexed minter, uint256 amount);

    /**
     * @dev Default amount of tokens to be minted by the faucet function.
     * Modify this value to adjust the default minting amount.
     */
    uint256 public DEFAULT_MINT_AMOUNT = 1000;

    /**
     * @dev Contract constructor.
     * It initializes the IcebearToken contract with the name "Icebear Token" and symbol "ICB".
     */
    constructor() ERC20("Icebear Token", "ICB") {
    }

    /**
     * @dev Faucet function that mints 1000 ICB tokens to the caller.
     */
    function faucet() public {
        uint256 amount = DEFAULT_MINT_AMOUNT * (10 ** decimals());
        _mint(msg.sender, amount);
        emit Faucet(msg.sender, DEFAULT_MINT_AMOUNT);
    }
}
