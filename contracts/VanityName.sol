// SPDX-License-Identifier: NONE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract VanityName {
    using SafeMath for uint256;
    using SafeMath for uint;
    uint public timeLockPeriod;
    address owner;
    bool locked;
    address  [] public  nameToOwner;
    constructor(uint32 _timeLockPeriod){
        timeLockPeriod = _timeLockPeriod;
        owner = msg.sender;
        locked = false;
    }
    struct NameBook {
        bytes name;
        uint256 value;
        uint256 time;
        bool isLocked;
    }
    mapping(address => NameBook) nameBook;
    mapping(string => address) ownerByname;

    modifier onlyOwner {
        require(msg.sender == owner, "Caller is not owner of registry service");
            _;
    }

    event NameRegistered(address indexed caller, bytes indexed name, uint256 value);
    event NameUnregistered(address indexed caller, bytes indexed name);
    event NameChanged(address indexed caller, bytes indexed name, uint256 value);
    event SetTimePeriod(uint timeLockPeriod);
    event BalanceWithdwalFromAccount(address indexed caller, uint256 value);
    event BalanceWithdwalByNameHolder(address indexed caller, uint256 value);
    event NameRemoval(address indexed caller, bytes indexed name);
    event Operational(bool operationalStatus);

    function setLockedValue(string memory _myString) pure private returns (uint) {
        bytes memory sizeOfString = bytes(_myString);
        uint valueForLock = uint(sizeOfString.length) * 10**18;
        return valueForLock;
    }

    function registerName(string memory _name) public payable {
        uint valueForLock = setLockedValue(_name);
        require(msg.value >= valueForLock, "Not enough value to register name");
        require(!locked, "Account is locked");
        bytes memory nameFromString = bytes(_name);
        uint256 timeLock =  timeLockPeriod.add(block.timestamp);
        nameBook[msg.sender] = NameBook({name: nameFromString, value: msg.value, time: timeLock, isLocked: true});
        nameToOwner.push(msg.sender);
        ownerByname[_name] = msg.sender;
        emit NameRegistered(msg.sender, nameFromString, msg.value);     
    }

    function checkExpiry()external onlyOwner{
        for(uint i=0; i < nameToOwner.length; i++ ){
            if (nameBook[nameToOwner[i]].time > block.timestamp){
                nameBook[nameToOwner[i]].name = " ";
                nameBook[nameToOwner[i]].time = 0;
                nameBook[nameToOwner[i]].isLocked = false;
                delete nameToOwner[i];
            }
        }
    }

    function setTimeLockPeriod  (uint _timeLockPeriod) external  onlyOwner {
        timeLockPeriod = _timeLockPeriod;
        emit SetTimePeriod(timeLockPeriod);
    }
    
    function setOpeartionalStatus(bool _operationalStatus) external onlyOwner {
        locked = _operationalStatus;
        emit Operational(_operationalStatus);
    }

    function withdrawAccountBalance () external onlyOwner {
      require(!locked, "Account is locked");
      require(address(this).balance > 0, "Balance is zero");
      payable (msg.sender).transfer(address(this).balance);
      emit BalanceWithdwalFromAccount(msg.sender, address(this).balance);
    }

    function removeName(address _removableNameAddress) external onlyOwner {
        require(!locked, "Account is locked");
        nameBook[_removableNameAddress].name = " ";
        nameBook[_removableNameAddress].time = 0;
        nameBook[msg.sender].isLocked = false;
        emit NameRemoval(msg.sender, nameBook[_removableNameAddress].name);
    }

    function withDrawLockValue () external {
        require(!locked, "Account is locked");
        require(block.timestamp > nameBook[msg.sender].time, "Too early");
        require(!nameBook[msg.sender].isLocked, "Name service in action, wait till expire");
        uint withdrawableBalance = nameBook[msg.sender].value;
        nameBook[msg.sender].value = 0;
        payable(msg.sender).transfer(withdrawableBalance);
        emit BalanceWithdwalByNameHolder(msg.sender, withdrawableBalance);
    }

    function getOwner(string memory _name) public view returns (address) {
        return ownerByname[_name];
    }

    function getBytesSize(string memory _myString) pure public returns(uint){
        bytes memory sizeOfString = bytes(_myString);
        return sizeOfString.length;
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getNameRegistryUserLength() public view returns (uint) {
        return nameToOwner.length;
    }

    function getOperationalStatus() public view returns(bool){
        return locked;
    }

    function getName(address _ownerAddress) public view returns (string memory) {
        string memory nameFromBytes = string(nameBook[_ownerAddress].name);
        return nameFromBytes;
    }
    function getNameCallByOwner() public view returns (string memory) {
        string memory nameFromBytes = string(nameBook[msg.sender].name);
        return nameFromBytes;
    }

    function getValue(address _owner) public view returns (uint256) {
        return nameBook[_owner].value;
    }

    fallback () external payable {

    }

    receive() external payable {
        
    }
}