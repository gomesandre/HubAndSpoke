pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/ownership/Ownable.sol';
import './RemittanceFactory.sol';

contract Remittance is Ownable{
    using SafeMath for uint256;
    
    uint constant FACTORY_FEE = 1 wei;
    
    struct Transfer {
        address sender;
        bytes32 puzzle;
        uint value;
        uint deadline;
    }
    
    Transfer t;
    RemittanceFactory factory;
    mapping (address => uint) public balances;
    
    event LogTransactionCreated(bytes32 puzzle, uint value);
    event LogTransactionCompleted(address indexed sender);
    event LogWithdrawn(address indexed sender, uint amount);
    event LogTransactionClaimedBack(bytes32 puzzle);
    event LogTransferedFee(uint value);
    
    constructor(address _factory) public {
        factory = RemittanceFactory(_factory);
    }
    
    modifier onlyDeployed() {
        require(factory.isRemittance(address(this)), "Only remittances deployed by factory can interact with the contract.");
        _;
    }
    
    function factoryFee(uint value) public returns (uint) {
        factory.addToBalance(FACTORY_FEE);
        return value.sub(FACTORY_FEE);
    }
    
    function create(bytes32 puzzle, uint hoursToExpire) public payable onlyDeployed {
        require(t.value == 0, "This remittance can only be used one time.");
        require(hoursToExpire > 1 && hoursToExpire <= 48, "Time until expiration must be between 1 and 48 hours.");
        require(msg.value >= 2, "Send at least 2 wei (factory fee is 1 wei).");
        uint expiresAt = now + (hoursToExpire * 1 hours);
        t = Transfer(msg.sender, puzzle, factoryFee(msg.value), expiresAt);
        emit LogTransactionCreated(puzzle, msg.value);
    }
    
    function release(bytes32 password) public {
        require(t.puzzle == generatePuzzle(password, msg.sender), "Incorrect puzzle.");
        require(t.deadline > now, "This remittance is expired.");
        require(t.value != uint(0), "Puzzle does not match or already released.");
        balances[msg.sender] += t.value;
        t.value = 0;
        emit LogTransactionCompleted(msg.sender);
    }
    
    function generatePuzzle(bytes32 password, address agent) public view returns (bytes32) {
        require(agent != address(0), "Invalid recipient.");
        return keccak256(abi.encodePacked(address(this), password, agent));
    }
    
    function withdraw() public {
        uint amount = balances[msg.sender];
        require(amount > 0, "Insufficient funds.");
        balances[msg.sender] = 0;
        emit LogWithdrawn(msg.sender, amount);
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Transfer failed.");
    }
}