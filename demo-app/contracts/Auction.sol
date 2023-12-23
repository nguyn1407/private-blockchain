//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract Auction is ERC721Holder, Ownable {
  
  IERC721 private nft;
  IERC20 private token;

  uint public constant AUCTION_SERVICE_FEE_RATE = 3;

  uint public constant MINIMUM_BID_RATE = 110;

  constructor (IERC20 _token, IERC721 _nft){
    token = _token;
    nft = _nft;
  }

  struct AuctionInfo{
    address auctioneer;
    uint256 _tokenId;
    uint256 initialPrice;

    address previousBidder;

    uint256 lastBid;
    address lastBidder;

    uint256 startTime;
    uint256 endTime;

    bool completed;
    bool active;
    uint256 auctionId;
  }

  AuctionInfo[] private auction;

  function createAuction(uint256 _tokenId, uint256 _initialPrice, uint256 _startTime, uint256 _endTime) public {
    require(block.timestamp <= _startTime, "Auction can not start");
    require(_startTime < _endTime, "Auction can not end before it starts");
    require(0 < _initialPrice, "Initial price must be greater than 0");

    require(nft.ownerOf(_tokenId) == msg.sender, "Must stake your own token");
    require(nft.getApproved(_tokenId) == address(this), "This contract must be approved to transfer the token");

    nft.safeTransferFrom(msg.sender, address(this), _tokenId);

    AuctionInfo memory _auction = AuctionInfo(
      msg.sender,         // aucitoneer
      _tokenId,           // tokenId
      _initialPrice ,     // initialPrice

      address(0),         // previousBidder
      _initialPrice,      // lastBid
      address(0),         // lastBidder

      _startTime,         // startTime
      _endTime,           // endTime

      false,              // complete
      true,               // active
      auction.length      // auctionId
    );

    auction.push(_auction);
  }

  function joinAuction(uint256 _auctionId, uint256 _bid) public {
    AuctionInfo memory _auction = auction[_auctionId];

    require(block.timestamp >= _auction.startTime, "Auction has not started");
    require(_auction.completed == false, "Auction is already completed");
    require(_auction.active, "Auction is not active");

    uint256 _minBid = _auction.lastBidder == address(0) ? _auction.initialPrice : _auction.lastBid * MINIMUM_BID_RATE/100;

    require(_minBid <= _bid, "Bid price must be greater than the minimum price");

    require(token.balanceOf(msg.sender) >= _bid, "Insufficient allowance");
    require(token.allowance(msg.sender, address(this)) >= _bid, "Insufficient allowance");

    require(_auction.auctioneer != msg.sender, "Can not bid on your own auction");

    // Next bidder transfer token to contract
    SafeERC20.safeTransferFrom(token, msg.sender, address(this), _bid);

    //Refund token to previous bidder
    if(_auction.lastBidder != address(0)){
      token.transfer(_auction.lastBidder, _auction.lastBid);
    }

    //update auction info
    auction[_auctionId].previousBidder = _auction.lastBidder;
    auction[_auctionId].lastBidder = msg.sender;
    auction[_auctionId].lastBid = _bid;
  }

  function cancelAuction(uint256 _auctionId) public onlyAuctioneer(_auctionId) {
        
        require(auction[_auctionId].completed == false, "Auction is already completed");
        require(auction[_auctionId].active, "Auction is not active");

        // Return NFT back to auctioneer
        nft.safeTransferFrom(address(this), auction[_auctionId].auctioneer, auction[_auctionId]._tokenId);

        // Refund token to previous bidder
        if (auction[_auctionId].lastBidder != address(0)) {
            token.transfer(auction[_auctionId].lastBidder, auction[_auctionId].lastBid);
        }
        auction[_auctionId].completed = true;
        auction[_auctionId].active = false;
    }


  function finishAuction(uint256 _auctionId) public onlyAuctioneer(_auctionId){
    require(auction[_auctionId].completed == false, "Auction is already completed");
    require(auction[_auctionId].active == false, "Auction is not active");

    nft.safeTransferFrom(address(this), auction[_auctionId].lastBidder, auction[_auctionId]._tokenId);
    
    uint256 lastBid = auction[_auctionId].lastBid;
    uint256 profit = lastBid - auction[_auctionId].initialPrice;

    uint256 auctionServiceFee = profit * AUCTION_SERVICE_FEE_RATE / 100;

    uint256 auctioneerRecieve = lastBid - auctionServiceFee;

    token.transfer(auction[_auctionId].auctioneer, auctioneerRecieve);

    auction[_auctionId].completed = true;
    auction[_auctionId].active = false;
  }

  function getAuction(uint256 _auctionId) public view returns(AuctionInfo memory){
    return auction[_auctionId];
  }

  function getAuctionByStatus(bool _active) public view returns (AuctionInfo[] memory){
    uint length = 0;
    for(uint i = 0; i < auction.length; i++){
      if(auction[i].active == _active){
        length++;
      }
    }

    AuctionInfo[] memory results = new AuctionInfo[](length);

    uint j = 0;
    for(uint256 index = 0; index < auction.length; index++){
      if(auction[index].active == _active){
        results[j] = auction[index];
      }
    }
    return results;
  }

  modifier onlyAuctioneer(uint256 _auctionId){
    require((msg.sender == auction[_auctionId].auctioneer || msg.sender == owner()), "Only auctioneer or owner can perform this action");
    _;
  }



}


