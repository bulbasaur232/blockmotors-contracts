// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/KIP/token/KIP17/KIP17.sol";
import "https://github.com/klaytn/klaytn-contracts/blob/master/contracts/access/Ownable.sol";

contract CarNFT is KIP17, Ownable{
    constructor() KIP17("CarNFT", "CAR") {}

}