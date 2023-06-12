// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {

    /**
    * @dev The address of the Icebear token contract.
    */
    address public icebearTokenAddress;

    /**
     * @dev Emitted when liquidity is added to the contract.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of tokens provided.
     * @param liquidity The amount of liquidity tokens minted.
     */
    event LiquidityAdded(address indexed provider, uint256 amount, uint256 liquidity);

    /**
     * @dev Emitted when liquidity is removed from the contract.
     * @param provider The address of the liquidity provider.
     * @param amount The amount of liquidity tokens burned.
     * @param celoAmount The amount of CELO tokens transferred to the provider.
     * @param icebearTokenAmount The amount of Icebear tokens transferred to the provider.
     */
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 celoAmount, uint256 icebearTokenAmount);

    /**
     * @dev Emitted when tokens are purchased from the contract.
     * @param buyer The address of the buyer.
     * @param celoAmount The amount of CELO tokens provided.
     * @param tokensBought The amount of Icebear tokens bought.
     */
    event TokensPurchased(address indexed buyer, uint256 celoAmount, uint256 tokensBought);

    /**
     * @dev Emitted when tokens are sold to the contract.
     * @param seller The address of the seller.
     * @param tokensSold The amount of Icebear tokens sold.
     * @param celoAmount The amount of CELO tokens transferred to the seller.
     */
    event TokensSold(address indexed seller, uint256 tokensSold, uint256 celoAmount);


    /**
     * @dev Initializes the AMM contract.
     * @param _icebearTokenAddress The address of the Icebear token.
     */
    constructor(address _icebearTokenAddress) ERC20("Icebear LP Token", "ICB-LP") {
        require(_icebearTokenAddress != address(0), "Token address passed is a null address");
        icebearTokenAddress = _icebearTokenAddress;
    }


    /**
     * @dev Returns the reserve of Icebear tokens held by the contract.
     * @return The reserve of Icebear tokens.
     */
    function getReserve() public view returns (uint) {
        return ERC20(icebearTokenAddress).balanceOf(address(this));
    }

    /**
     * @dev Adds liquidity to the AMM contract.
     * @param _amount The amount of Icebear tokens to add.
     * @return The amount of liquidity added.
     */
    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint celoBalance = address(this).balance;
        uint icebearTokenReserve = getReserve();
        ERC20 icebearToken = ERC20(icebearTokenAddress);
        if(icebearTokenReserve == 0) {
            require(icebearToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed");
            liquidity = celoBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint celoReserve = celoBalance - msg.value;
            uint icebearTokenAmount = (msg.value * icebearTokenReserve)/(celoReserve);
            require(_amount >= icebearTokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            require(icebearToken.transferFrom(msg.sender, address(this), icebearTokenAmount), "Token transfer failed");
            liquidity = (msg.value * totalSupply()) / celoReserve;
            require(liquidity > 0, "Liquidity amount is zero");
            _mint(msg.sender, liquidity);
        }
        emit LiquidityAdded(msg.sender, _amount, liquidity);
         return liquidity;
    }

    /**
     * @dev Removes liquidity from the AMM contract.
     * @param _amount The amount of LP tokens to remove.
     * @return The amount of CELO and Icebear tokens received.
     */
    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "LP amount must be greater than zero");
        require(balanceOf(msg.sender) >= _amount, "Insufficient LP tokens to burn");
        uint celoReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint celoAmount = (celoReserve * _amount)/ _totalSupply;
        uint icebearTokenAmount = (getReserve() * _amount)/ _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(celoAmount);
        ERC20(icebearTokenAddress).transfer(msg.sender, icebearTokenAmount);
        emit LiquidityRemoved(msg.sender, _amount, celoAmount, icebearTokenAmount);
        return (celoAmount, icebearTokenAmount);
    }

    /**
     * @dev Calculates the amount of output tokens for a given input amount and reserves.
     * @param inputAmount The input amount of tokens.
     * @param inputReserve The input reserve of tokens.
     * @param outputReserve The output reserve of tokens.
     * @return The amount of output tokens.
     */
    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;
        return numerator / denominator;
    }


    /**
     * @dev Swaps CELO for Icebear tokens.
     * @param _minTokens The minimum amount of Icebear tokens expected to be received.
     */
    function celoToIcebearToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient output amount");
        ERC20(icebearTokenAddress).transfer(msg.sender, tokensBought);
        require(checkTransferSuccess(), "Token transfer failed");
        emit TokensPurchased(msg.sender, msg.value, tokensBought);
    }

    /**
    * @dev Checks if the token transfer from the contract to itself is successful.
    * @return A boolean indicating whether the transfer was successful or not.
    */
    function checkTransferSuccess() private returns (bool) {
    uint256 tokenBalance = ERC20(icebearTokenAddress).balanceOf(address(this));
    return (tokenBalance == 0 || ERC20(icebearTokenAddress).transfer(address(this), tokenBalance));
    }


    /**
     * @dev Swaps Icebear tokens for CELO.
     * @param _tokensSold The amount of Icebear tokens to sell.
     * @param _minCelo The minimum amount of CELO expected to be received.
     */
    function icebearTokenToCelo(uint _tokensSold, uint _minCelo) public {
        uint256 tokenReserve = getReserve();
        
        uint256 celoBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(celoBought >= _minCelo, "Insufficient output amount");
        require(
            ERC20(icebearTokenAddress).transferFrom(
                msg.sender,
                address(this),
                _tokensSold
            ),
            "Token transfer failed"
        );
        payable(msg.sender).transfer(celoBought);
        emit TokensSold(msg.sender, _tokensSold, celoBought);
    }
}
