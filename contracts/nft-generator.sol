// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/KIP/token/KIP17/KIP17.sol";
import "@klaytn/contracts/access/Ownable.sol";

contract CarNFT is KIP17, Ownable{
    constructor() KIP17("CarNFT", "CAR") {}

}