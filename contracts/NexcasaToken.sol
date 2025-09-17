// contracts/tokens/NexcasaToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NexcasaToken is ERC20, Ownable {
    // Terima initialSupply sebagai parameter
    constructor(uint256 initialSupply) ERC20("Nexcasa", "NEXCASA") Ownable(msg.sender) {
        // Cetak jumlah token sesuai input parameter
        _mint(msg.sender, initialSupply);
    }
}