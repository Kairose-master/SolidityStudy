// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts@5.4.0/token/ERC20/ERC20.sol";
import {ERC721} from "@openzeppelin/contracts@5.4.0/token/ERC721/ERC721.sol";

/// @dev Local demo token only. Anyone can deploy their own instance.
contract DemoGameToken is ERC20 {
    constructor(address initialHolder, uint256 initialSupply)
        ERC20("Arena Game Token", "AGT")
    {
        _mint(initialHolder, initialSupply);
    }
}

/// @dev Local demo NFT only. Anyone can mint heroes for testing.
contract DemoHeroNFT is ERC721 {
    uint256 private nextTokenId = 1;

    constructor() ERC721("Arena Hero", "HERO") {}

    function mint(address to) external returns (uint256 tokenId) {
        tokenId = nextTokenId++;
        _safeMint(to, tokenId);
    }
}
