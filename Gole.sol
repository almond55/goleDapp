pragma solidity ^0.5.4;

import "./GoleToken.sol";

contract Gole is GoleToken {
    constructor () public ERC20Detailed("Game Of Life Experience", "GOLE", 18) {
        _mint(msg.sender, 1000000000 * (10 ** uint256(decimals())));
        // start at 0.2%
        setFee(2);
    }
}