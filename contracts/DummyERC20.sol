// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DummyERC20 is ERC20 {
    constructor() ERC20("Dummy ERC721", "DUMMY") {
        _mint(msg.sender, 1_000_000 ether);
    }

    function decimals() public pure override returns (uint8) {
        return 9;
    }
}
