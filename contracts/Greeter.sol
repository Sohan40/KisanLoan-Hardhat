// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import "hardhat/console.sol";

contract Greeter {
    string public greeting;

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }
}