pragma solidity ^0.4.24;

import "./Ownable.sol";
import "./Medianizer.sol";

contract ChainmonstersMedianizer is Ownable {

    address medianizerBase;
    Medianizer makerMed;

    constructor(address _medianizerContract) public {
        owner = msg.sender;

        medianizerBase = _medianizerContract;

        makerMed = Medianizer(medianizerBase);
    }

    function updateMedianizerBase(address _medianizerContract) public onlyOwner {
        medianizerBase = _medianizerContract;
        makerMed = Medianizer(medianizerBase);
    }

    function getUSDPrice() public view returns (uint256) {
        return bytesToUint(toBytes(makerMed.read()));
    }
    
    function isMedianizer() public view returns (bool) {
        return true;
    }
    
    

    function toBytes(bytes32 _data) public pure returns (bytes) {
        return abi.encodePacked(_data);
    }

    function bytesToUint(bytes b) public pure returns (uint256){
        uint256 number;
        for(uint i=0;i<b.length;i++){
            number = number + uint(b[i])*(2**(8*(b.length-(i+1))));
        }
        return number;
    }

}