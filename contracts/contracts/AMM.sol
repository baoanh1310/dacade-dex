// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {

    address public icebearTokenAddress;

    constructor(address _icebearTokenAddress) ERC20("Icebear LP Token", "ICB-LP") {
        require(_icebearTokenAddress != address(0), "Token address passed is a null address");
        icebearTokenAddress = _icebearTokenAddress;
    }

    function getReserve() public view returns (uint) {
        return ERC20(icebearTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns (uint) {
        uint liquidity;
        uint celoBalance = address(this).balance;
        uint icebearTokenReserve = getReserve();
        ERC20 icebearToken = ERC20(icebearTokenAddress);
        if(icebearTokenReserve == 0) {
            icebearToken.transferFrom(msg.sender, address(this), _amount);
            liquidity = celoBalance;
            _mint(msg.sender, liquidity);
        } else {
            uint celoReserve = celoBalance - msg.value;
            uint icebearTokenAmount = (msg.value * icebearTokenReserve)/(celoReserve);
            require(_amount >= icebearTokenAmount, "Amount of tokens sent is less than the minimum tokens required");
            icebearToken.transferFrom(msg.sender, address(this), icebearTokenAmount);
            liquidity = (totalSupply() * msg.value)/ celoReserve;
            _mint(msg.sender, liquidity);
        }
         return liquidity;
    }

    function removeLiquidity(uint _amount) public returns (uint , uint) {
        require(_amount > 0, "LP amount must be greater than zero");
        uint celoReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint celoAmount = (celoReserve * _amount)/ _totalSupply;
        uint icebearTokenAmount = (getReserve() * _amount)/ _totalSupply;
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(celoAmount);
        ERC20(icebearTokenAddress).transfer(msg.sender, icebearTokenAmount);
        return (celoAmount, icebearTokenAmount);
    }

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

    function celoToIcebearToken(uint _minTokens) public payable {
        uint256 tokenReserve = getReserve();
        
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient output amount");
        ERC20(icebearTokenAddress).transfer(msg.sender, tokensBought);
    }


    function icebearTokenToCelo(uint _tokensSold, uint _minCelo) public {
        uint256 tokenReserve = getReserve();
        
        uint256 celoBought = getAmountOfTokens(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(celoBought >= _minCelo, "Insufficient output amount");
        ERC20(icebearTokenAddress).transferFrom(
            msg.sender,
            address(this),
            _tokensSold
        );
        payable(msg.sender).transfer(celoBought);
    }
}