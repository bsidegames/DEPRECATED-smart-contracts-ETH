import "chainmonsterscore.sol";











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






contract GameLogic {

    using SafeMath for uint256;

    uint256 public gasCosts;
    uint256 public mintCosts;
    uint256 public mintFee;

    address public backend;
    ChainMonstersCore public coreContract;

    address public admin;

    address public owner;

    // token = 0 => not requested yet
    // token = 1 => requested
    // token = 2 => minted
    mapping(uint256 => uint16) tokenToMinted;


    // Events
    event RequestMint(address _from, uint256 _id);
    event MintToken(uint256 _tokenId, address _owner);


    constructor() public {
        owner = msg.sender;
    }

    

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == admin);
        require(_gasFee > 0);
        gasCosts = _gasFee;


    }

    function setMintFee(uint256 _mintFee) public {
        require(msg.sender == admin);
        require(_mintFee > 0);
        mintCosts = _mintFee;

        
    }

    function setAdmin(address _admin) public {
        require(msg.sender == admin);
        admin = _admin;
    }

    // _id here is NOT the final tokenID and instead an internal identifier
    // the core contract later creates the real tokenId
    // this method does not require the actual owner to call this
    // which enables us to do promo minting for players during special events
    // and also other players to gift each other a caught monster ;)
    function requestMintToken(uint256 _id) payable public {
        require(tokenToMinted[_id] == 0);
        require(msg.value >= mintFee);
        backend.transfer(gasCosts);
        tokenToMinted[_id] = 1;

        RequestMint(msg.sender, _id);


    }

    // mint method called by server
    // the gasFee sent by the player makes sure that the system runs without further user interaction required
    // minted tokens are Gen-1 as specified in coreContract.SpawnMonster method
    function mintToken(uint256 _id, uint256 _mid, address _owner) public {
        require(msg.sender == backend);
        require(tokenToMinted[_id] == 1);
        require(_mid >= 1 && _mid <= 151);

        

        // start off with blocking any attemps of creating any duplicates
        tokenToMinted[_id] = 2;

        coreContract.SpawnMonster(_mid, _owner);

        MintToken(_id, _owner);

    }

    function withdrawBalance() external  
    {
        require(msg.sender == owner);

        // there is never more balancee on this contract than the sum if the mintFee
        // since gas costs are handled during each new request automatically
        uint256 balance = this.balance;
        owner.transfer(balance);
    }

}