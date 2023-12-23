//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CrowdSale is Ownable{
    using SafeERC20 for IERC20;

    address payable public _wallet;
    uint256 public BNB_rate;
    uint256 public USDT_rate;
    IERC20 public token;
    IERC20 public usdtToken;

    event SetUSDTToken(IERC20 token_address);
    event SetBNBRate(uint256 new_rate);
    event SetUSDTRate(uint256 new_rate);
    event BuyTokenByBNB(address buyer, uint256 amount);
    event BuyTokenByUSDT(address buyer, uint256 amount);
   
    constructor(
        uint256 bnb_rate,
        uint256 usdt_rate,
        address payable wallet,
        IERC20 icotoken
    ){
        BNB_rate = bnb_rate;
        USDT_rate = usdt_rate;
        _wallet = wallet;
        token = icotoken;
    }

    function setUSDTToken(IERC20 token_address) public onlyOwner{
        usdtToken = token_address;
        emit SetUSDTToken(token_address);
    }

    function setBNBRate(uint256 new_rate) public onlyOwner(){
        BNB_rate = new_rate;
        emit SetBNBRate(new_rate);
    }

    function setUSDTRate(uint256 new_rate) public onlyOwner{
        USDT_rate = new_rate;
        emit SetUSDTRate(new_rate);
    }

    function buyTokenByBNB() external payable {
        uint256 bnbAmount = msg.value;
        uint256 amount = getTokenAmountBNB(bnbAmount);

        require(amount > 0, "Amount is Zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficent acount ballance");
        require(msg.sender.balance >= amount, "Insufficient account balance");

        payable(_wallet).transfer(bnbAmount);
        SafeERC20.safeTransfer(token, msg.sender, amount);

        emit BuyTokenByBNB(msg.sender, amount);
    }

    function getTokenAmountBNB(uint256 BNBAmount) public view returns(uint256) {
        return BNBAmount * BNB_rate;
    }

    function buyTokenByUSDT(uint256 USDTAmount) external {
        uint256 amount = getTokenAmountUSDT(USDTAmount);

        require(usdtToken.balanceOf(msg.sender) >= USDTAmount, "Insufficient account balance"); 

        require(amount > 0, "Amount is zero");
        require(token.balanceOf(address(this)) >= amount, "Insufficient account balance");

        SafeERC20.safeTransferFrom(usdtToken, msg.sender, _wallet, USDTAmount);
        SafeERC20.safeTransfer(token, msg.sender, amount);

        emit BuyTokenByUSDT(msg.sender, amount);
    }

    function getTokenAmountUSDT(uint256 USDTAmount) public view returns(uint256){
        return USDTAmount * USDT_rate;
    }

    function withdraw() public onlyOwner(){
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20() public onlyOwner(){
        usdtToken.transfer(msg.sender, usdtToken.balanceOf(address(this)));
    }

}
    