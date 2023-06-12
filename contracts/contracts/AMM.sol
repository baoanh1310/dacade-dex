// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMM is ERC20 {

    address public icebearTokenAddress;

    event LiquidityAdded(address indexed provider, uint256 amount, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amount, uint256 celoAmount, uint256 icebearTokenAmount);
    event TokensPurchased(address indexed buyer, uint256 celoAmount, uint256 tokensBought);
    event TokensSold(address indexed seller, uint256 tokensSold, uint256 celoAmount);

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
        require(checkTransferSuccess(), "Token transfer failed");
        emit TokensPurchased(msg.sender, msg.value, tokensBought);
    }

    function checkTransferSuccess() private returns (bool) {
    uint256 tokenBalance = ERC20(icebearTokenAddress).balanceOf(address(this));
    return (tokenBalance == 0 || ERC20(icebearTokenAddress).transfer(address(this), tokenBalance));
}


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
