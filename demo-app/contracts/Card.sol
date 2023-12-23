//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface ICard {
  function mint(address to, uint card_type) external returns(uint256);
}

contract Card is ERC721Enumerable, Ownable, AccessControlEnumerable, ICard{
  using Counters for Counters.Counter;    
  Counters.Counter private _tokenIdTracker;
  string private _url;
  bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

  event Mint(address to, uint256 card_item, uint256 token_id);

  constructor() ERC721("Sticky Card", "Card"){
    _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
  }

  function _baseURI() internal view override returns(string memory _newBaseURI){
    return _url;
  }

  function mint(address to, uint256 item_type) external override returns(uint256){
    require(owner() == _msgSender() || hasRole(MINTER_ROLE, _msgSender()), "Caller is not minter");
    _tokenIdTracker.increment();
    uint256 token_id = _tokenIdTracker.current();
    _mint(to, token_id);
    emit Mint(to, item_type, token_id);
    return token_id;
  }

  function listTokenIds(address owner) external view returns(uint256[] memory tokenIds){
    uint256 balance = balanceOf(owner);
    uint256[] memory ids = new uint256[](balance);

    for(uint i = 0; i<balance; i++){
      ids[i] = tokenOfOwnerByIndex(owner, i);
    }

    return ids;
  }

  function setBaseUrl(string memory _newUrl) public onlyOwner{
    _url = _newUrl;
  }

  function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721Enumerable, AccessControlEnumerable) returns (bool){
    return super.supportsInterface(interfaceId);
  }
}
