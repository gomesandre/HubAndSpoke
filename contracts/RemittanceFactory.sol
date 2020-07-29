pragma solidity ^0.5.0;

import "@openzeppelin/contracts/math/SafeMath.sol";
import '@openzeppelin/contracts/ownership/Ownable.sol';
import './Remittance.sol';

contract RemittanceFactory is Ownable{
    using SafeMath for uint256;
    
    address[] public remittances;
    mapping (address => uint) public balances;
    mapping(address => bool) public isRemittance;
    
    event LogNewRemittance(address sender, address remittance);
    event LogWithdrawn(address indexed sender, uint amount);
    
    modifier onlyDeployed() {
        require(isRemittance[msg.sender], "Only remittances deployed by factory can interact with the contract.");
        _;
    }
    
    function createRemittance() public returns (Remittance newRemittance) {
        newRemittance = new Remittance(address(this));
        newRemittance.transferOwnership(msg.sender);
        remittances.push(address(newRemittance));
        isRemittance[address(newRemittance)] = true;
        emit LogNewRemittance(msg.sender, address(newRemittance));
    }
    
    function addToBalance(uint value) public onlyDeployed {
        address owner = owner();
        balances[owner] = balances[owner].add(value);
    }
    
    function withdraw() public onlyOwner {
        uint amount = balances[msg.sender];
        require(amount > 0, "Insufficient funds.");
        balances[msg.sender] = 0;
        emit LogWithdrawn(msg.sender, amount);
        (bool success, ) = msg.sender.call.value(amount)("");
        require(success, "Transfer failed.");
    }
}