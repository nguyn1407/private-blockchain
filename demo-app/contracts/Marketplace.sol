//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract Marketplace is ERC721Holder, Ownable{
  using SafeERC20 for IERC20;

  IERC721Enumerable private nft;
  IERC20 private token;

  struct ListDetail {
    address payable author;
    uint256 price;
    uint256 tokenId;
  }

  mapping(uint256 => ListDetail) listDetail;
  uint256 private tax = 10;

  //event
  event SetTax(uint256 _tax);
  event SetToken(IERC20 _token);
  event SetNft(IERC721Enumerable _nft);

  event ListNft(address indexed _from, uint256 _tokenid, uint256 _price);
  event UpdateListingNftPrice(uint _tokenid, uint256 _price);
  event UnListNft(address indexed _from, uint256 _tokenId);
  event BuyNft(address from,uint256 _tokenId, uint256 _price);
  

  constructor(IERC20 _token, IERC721Enumerable _nft){
    nft = _nft;
    token = _token;
  }

  // function onERC721Received(
  //   address,
  //   address,
  //   uint256,
  //   bytes calldata
  // )external override pure returns (bytes4){
  //   return bytes4(
  //     keccak256("onERC721Received(address, address, uint256, bytes)")
  //   );
  // }

  function setTax(uint256 _tax) public onlyOwner{
    tax = _tax;
    emit SetTax(_tax);
  }

  function setToken(IERC20 _token) public onlyOwner{
    token = _token;
    emit SetToken(_token);
  }

  function setNft(IERC721Enumerable _nft) public onlyOwner{
    nft = _nft;
    emit SetNft(_nft);
  }

  function getListedNft() view public returns(ListDetail [] memory){
    uint256 balance = nft.balanceOf(address(this));
    ListDetail[] memory myNft = new ListDetail[](balance);

    for(uint i=0; i < balance; i++){
      myNft[i] = listDetail[nft.tokenOfOwnerByIndex(address(this),i)];
    }

    return myNft;
  }

  function listNft(uint256 _tokenId, uint256 _price) public {
    require(nft.ownerOf(_tokenId) == msg.sender, "You are not owner of this nft");
    require(nft.getApproved(_tokenId) == address(this), "Marketplace is not approval to tranfer this nft");

    listDetail[_tokenId] = ListDetail(payable(msg.sender), _price, _tokenId);

    nft.safeTransferFrom(msg.sender, address(this), _tokenId);
    
    emit ListNft(msg.sender, _tokenId, _price);
  }

  function updateListNftPrice(uint256 _tokenId, uint256 _price) public {
    require(nft.ownerOf(_tokenId) == address(this), "You are not owner of this nft");
    require(listDetail[_tokenId].author == msg.sender, "Only owner can update price of this Nft");

    listDetail[_tokenId].price = _price;

    emit UpdateListingNftPrice(_tokenId, _price);
  }

  function unListnft(uint256 _tokenId) public {
    require(nft.ownerOf(_tokenId) == address(this), "This token doesn't exit on marketplace");
    require(listDetail[_tokenId].author == msg.sender, "Only Owner can unlist this nft");

    nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    
    emit UnListNft(msg.sender, _tokenId);
  }

  function buyNft(uint256 _tokenId, uint256 _price) public {
    require(token.balanceOf(msg.sender) >= _price, "Insufficient account balance");
    require(nft.ownerOf(_tokenId) == address(this), "This Nft doesn't exit on marketplace");
    require(listDetail[_tokenId].price <= _price, "Minimum price has not been reached");

    SafeERC20.safeTransferFrom(token, msg.sender, address(this), _price);
    token.transfer(listDetail[_tokenId].author, _price * (100 - tax)/ 100);

    nft.safeTransferFrom(address(this), msg.sender, _tokenId);

    emit BuyNft(msg.sender, _tokenId, _price);
  }

  function withdraw() public onlyOwner{
    payable(msg.sender).transfer(address(this).balance);
  }

  function withdrawToken(uint amount) public onlyOwner{
    require(token.balanceOf(address(this)) >= amount, "Insufficient contract balance");
    token.transfer(msg.sender, amount);
  }

  function withdrawERC20() public onlyOwner{
    token.transfer(msg.sender, token.balanceOf(address(this)));
  }

}