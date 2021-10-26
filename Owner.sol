pragma solidity ^0.5.4;

contract Owner{
    // some functions should only be done by admin
    address private _owner;

    constructor () internal {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }
}