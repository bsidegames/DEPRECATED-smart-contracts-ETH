pragma solidity ^0.5.2;

import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC721/ERC721Full.sol";
import "http://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";



contract ChainmonstersCoreV2 is ERC721Full, Ownable{
    
    address public GameContract;
    string baseAPI = "http://chainmonsters.appspot.com/api/GetMonster/";
    string public offset = "100000";
    

    
    constructor() ERC721Full("Chainmonsters", "CHMON") public {
        
    }
    
    
    
    
    function mintToken(address _to) public {
        require(msg.sender == GameContract);
        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
    }
    
    function setGameContract(address _contract) public onlyOwner {
        GameContract = _contract;
    }
    
    function setOffset(string memory _offset) public onlyOwner {
        offset = _offset;
    }
    
    function tokenURI(uint256 _tokenId) public view returns (string memory) {
    return append(baseTokenURI(), offset, uint2str(_tokenId));
  }

    /**
    * @dev calculates the next token ID based on totalSupply
    * @return uint256 for the next token ID
    */
    function _getNextTokenId() private view returns (uint256) {
        return totalSupply().add(1); 
    }
    
    function baseTokenURI() public view returns (string memory) {
        return baseAPI;
    }
    
    function append(string memory a, string memory b, string memory c) internal pure returns (string memory) {

    return string(abi.encodePacked(a, b, c));

}
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint j = _i;
    uint len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint k = len - 1;
    while (_i != 0) {
        bstr[k--] = byte(uint8(48 + _i % 10));
        _i /= 10;
    }
    return string(bstr);
}
    
} 