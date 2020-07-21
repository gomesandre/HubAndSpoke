pragma solidity ^0.5.0;

import './Remittance.sol';

contract RemittanceFactory {
    address[] public remittances;
    mapping(address => bool) public isRemittance;
    
    event LogNewRemittance(address sender, address remittance);
    
    function getRemittanceCount() public view returns(uint count) { return remittances.length; }
    
    function createRemittance() public returns (Remittance newRemittance) {
        newRemittance = new Remittance(address(this));
        remittances.push(address(newRemittance));
        isRemittance[address(newRemittance)] = true;
        emit LogNewRemittance(msg.sender, address(newRemittance));
    }
}