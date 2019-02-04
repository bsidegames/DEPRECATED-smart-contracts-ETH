
//
// Our shop contract acts as a payment provider for our in-game shop system. 
// Coin packages that are purchased here are being picked up by our offchain 
// sync network and are then translated into in-game assets. This happens with
// minimal delay and enables a fluid gameplay experience. An in-game notification
// informs players about the successful purchase of coins.
// 
// Prices are scaled against the current USD value of ETH courtesy of
// MAKERDAO (https://developer.makerdao.com/feeds/) 
// This enables us to match our native In-App-Purchase prices from e.g. Apple's AppStore
// We can also reduce the price of packages temporarily for e.g. events and promotions.
//

pragma solidity ^0.4.21;

import "./Medianizer.sol";
import "./ChainmonstersMedianizer.sol";

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
    * @dev Substracts two numbers, returns 0 if it would go into minus range.
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        if (b >= a) {
            return 0;
        }
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ChainmonstersShop {
    using SafeMath for uint256; 
    
    // static
    address public owner;
    
    // start auction manually at given time
    bool started;

    uint256 public totalCoinsSold;

    address medianizer;
    uint256 shiftValue = 100; // double digit shifting to support prices like $29.99
    uint256 multiplier = 10000; // internal multiplier

    struct Package {
        // price in USD
        uint256 price;
        // reference to in-game equivalent e.g. "100 Coins"
        string packageReference;
        // available for purchase?
        bool isActive;
        // amount of coins
        uint256 coinsAmount;
    }

    
    event LogPurchase(address _from, uint256 _price, string _packageReference);

    mapping(address => uint256) public addressToCoinsPurchased;
    Package[] packages;

    constructor() public {
        owner = msg.sender;

        started = false;
        
        _addPackage(99, "100 Coins", true, 100);
        _addPackage(549, "550 Coins", true, 550);
        _addPackage(1099, "1200 Coins", true, 1200);
        _addPackage(2199, "2500 Coins", true, 2500);
        _addPackage(4399, "5200 Coins", true, 5200);
        _addPackage(10999, "14500 Coins", true, 14500);
        
    }

    function startShop() public onlyOwner {
        require(started == false);
        started = true;
    }

    // in case of contract switch or adding new packages
    function pauseShop() public onlyOwner {
        require(started == true);
        started = false;
    }

    function isStarted() public view returns (bool success) {
        return started;
    }

    function purchasePackage(uint256 _id) public
        payable
        returns (bool success)
        {
            require(started == true);
            require(packages[_id].isActive == true);
            require(msg.sender != owner);
            require(msg.value == priceOf(packages[_id].price)); // only accept 100% accurate prices

            addressToCoinsPurchased[msg.sender] += packages[_id].coinsAmount;
            totalCoinsSold += packages[_id].coinsAmount;
            emit LogPurchase(msg.sender, msg.value, packages[_id].packageReference);
        }
        
    function _addPackage(uint256 _price, string _packageReference, bool _isActive, uint256 _coinsAmount)
        internal
        {
            require(_price > 0);
            Package memory _package = Package({
            price: uint256(_price),
            packageReference: string(_packageReference),
            isActive: bool(_isActive),
            coinsAmount: uint256(_coinsAmount)
        });

        uint256 newPackageId = packages.push(_package);

        }

    function addPackage(uint256 _price, string _packageReference, bool _isActive, uint256 _coinsAmount)
        external
        onlyOwner
        {
            _addPackage(_price, _packageReference, _isActive, _coinsAmount);
        }
        
    function setPackageActive(uint256 _id, bool _active)
        external
        onlyOwner
        {
            packages[_id].isActive = _active;
        }

    function setPrice(uint256 _packageId, uint256 _newPrice)
        external
        onlyOwner
        {
            require(packages[_packageId].price > 0);
            packages[_packageId].price = _newPrice;
        }

    function getPackage(uint256 _id)
        external 
        view
        returns (uint256 priceInETH, uint256 priceInUSD, string packageReference, uint256 coinsAmount )
        {
            Package storage package = packages[_id];
            priceInETH = priceOf(_id);
            priceInUSD = package.price;
            packageReference = package.packageReference;
            coinsAmount = package.coinsAmount;
        
        }

 
  function priceOf(uint256 _packageId)
    public
    view
    returns (uint256) 
    {

        // if no medianizer is set then return fixed price(!)
        if (medianizer == address(0x0)) {
          return packages[_packageId].price;
        }
        else {
          // the price of usd/eth gets returned from medianizer
          uint256 USDinWei = ChainmonstersMedianizer(medianizer).getUSDPrice();
    
          uint256 multValue = (packages[_packageId].price.mul(multiplier)).div(USDinWei.div(1 ether));
          uint256 inWei = multValue.mul(1 ether);
          uint256 result = inWei.div(shiftValue.mul(multiplier));
          return result;
        }
    
  }
  
  function getPackagesCount()
    public
    view
    returns (uint256)
    {
        return packages.length;
    }

  function setMedianizer(ChainmonstersMedianizer _medianizer)
     public
    onlyOwner 
    {
    require(_medianizer.isMedianizer(), "given address is not a medianizer contract!");
    medianizer = _medianizer;
  }

    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function withdrawBalance()
        external 
        onlyOwner 
        {
            uint256 balance = this.balance;
            owner.transfer(balance);
        }
  
}