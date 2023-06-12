// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AMM is ERC20 {
    using Address for address;

    using SafeMath for uint256;

    address public icebearTokenAddress;

    constructor(address _icebearTokenAddress) ERC20("Icebear LP Token", "ICB-LP") {
        require(_icebearTokenAddress.isContract(), "Token address passed is not a contract");
        icebearTokenAddress = _icebearTokenAddress;
    }

    function getReserve() public view returns (uint reserveAmount) {
        return ERC20(icebearTokenAddress).balanceOf(address(this));
    }

    function addLiquidity(uint _amount) public payable returns (uint returnedliquidity) {
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
            liquidity = (msg.value.mul(totalSupply())).div(celoReserve);
            _mint(msg.sender, liquidity);
        }
         return liquidity;
    }

    function removeLiquidity(uint _amount) public returns (uint celoamount, uint icebeartokenamount) {
        require(_amount > 0, "LP amount must be greater than zero");
        uint celoReserve = address(this).balance;
        uint _totalSupply = totalSupply();
        uint celoAmount = celoReserve.mul(_amount).div(_totalSupply);
        uint icebearTokenAmount = getReserve().mul(_amount).div(_totalSupply);
        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(celoAmount);
        ERC20(icebearTokenAddress).transfer(msg.sender, icebearTokenAmount);
        return (celoAmount, icebearTokenAmount);
    }

    function getAmountOfTokens(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) public pure returns (uint256 tokensAmount) {
        require(inputReserve > 0 && outputReserve > 0, "Invalid reserves");
        uint256 inputAmountWithFee = inputAmount.mul(99);
        uint256 numerator = inputAmountWithFee.mul(outputReserve);
        uint256 denominator = inputReserve.mul(100).add(inputAmountWithFee);
        return numerator.div(denominator);
    }

    function celoToIcebearToken(uint _minTokens) public payable returns (uint256 purchasedTokens) {
        uint256 tokenReserve = getReserve();
        
        uint256 tokensBought = getAmountOfTokens(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "Insufficient output amount");
        ERC20(icebearTokenAddress).transfer(msg.sender, tokensBought);
        return purchasedTokens;
    }


    function icebearTokenToCelo(uint _tokensSold, uint _minCelo) public returns (uint256 boughtCelo){
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
        return boughtCelo;
    }
}
