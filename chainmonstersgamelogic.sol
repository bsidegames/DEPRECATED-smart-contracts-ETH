




pragma solidity ^0.5.2;

import "browser/chainmonsterscorev2.sol";







contract GameLogic {

    using SafeMath for uint256;

    uint256 public gasCosts;
    uint256 public mintCosts;
    uint256 public mintFee;

    address payable public backend;
    ChainmonstersCoreV2 public coreContract;
    address public core;
    
    bool public isGameLogicContract = true;

    address public admin;

    address public owner;

    // token = 0 => not requested yet
    // token = 1 => requested
    // token = 2 => minted
    mapping(uint256 => uint16) public tokenToMinted;


    // Events
    event RequestMint(address _from, uint256 _id, uint256 mintFee, uint256 gasFee);
    event MintToken(uint256 _tokenId, address _owner);


    constructor(address _core) public {
        owner = msg.sender;
        admin = msg.sender;
        backend = msg.sender;
        core = _core;
        coreContract = ChainmonstersCoreV2(_core);

    }

    

    function setGasFee(uint256 _gasFee) public {
        require(msg.sender == admin);
        require(_gasFee > 0);
        gasCosts = _gasFee;
        
        mintFee = mintCosts + gasCosts;


    }

    function setMintFee(uint256 _mintFee) external {
        require(msg.sender == admin);
        require(_mintFee > 0);
        mintCosts = _mintFee;
        mintFee = mintCosts + gasCosts;

        
    }

    function setAdmin(address _admin) external {
        require(msg.sender == admin);
        require(_admin == address(_admin));
        admin = _admin;
    }
    
    function setBackend(address payable _backend) external {
        require(msg.sender == admin);
        require(_backend == address(_backend));
        backend = _backend;
    }
    
    function setCoreContract(address _core) external {
        require(msg.sender == admin);
        require(_core == address(_core));
        coreContract = ChainmonstersCoreV2(_core);
        core = _core;
    }

    // _id here is NOT the final tokenID and instead an internal identifier
    // the core contract later creates the real tokenId
    // this method does not require the actual owner to call this
    // which enables us to do promo minting for players during special events
    // and also other players to gift each other a caught monster ;)
    function requestMintToken(uint256 _id) payable external {
        require(tokenToMinted[_id] == 0);
        require(msg.value == mintFee);
        backend.transfer(gasCosts);
        tokenToMinted[_id] = 1;

        emit RequestMint(msg.sender, _id, mintFee, gasCosts);


    }

    // mint method called by server
    // the gasFee sent by the player makes sure that the system runs without further user interaction required
    function mintToken(uint256 _id, address _owner) external {
        require(msg.sender == backend);
        require(tokenToMinted[_id] == 1);
       

        

        // start off with blocking any attemps of creating any duplicates
        tokenToMinted[_id] = 2;

        coreContract.mintToken(_owner);

        emit MintToken(_id, _owner);

    }

    function withdrawBalance() external  
    {
        require(msg.sender == owner);

        // there is never more balancee on this contract than the sum of the mintFee
        // since gas costs are handled during each new request automatically
        uint256 balance = address(this).balance;
        address payable _owner = address(uint160(owner));
        _owner.transfer(balance);
    }

}