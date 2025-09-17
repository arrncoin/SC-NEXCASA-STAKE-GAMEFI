// contracts/CustomERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CustomERC20 is ERC20, Ownable {
    // Variabel privat untuk menyimpan nilai desimal kustom kita
    uint8 private _customDecimals;

    /**
     * @param name_ Nama token
     * @param symbol_ Simbol token
     * @param decimals_ Jumlah angka di belakang koma
     * @param initialSupply_ Jumlah pasokan awal (SUDAH TERMASUK DESIMAL)
     * @param owner_ Alamat yang akan menjadi owner
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        address owner_
    // KOREKSI: Panggilan constructor ERC20 kembali ke 2 argumen
    ) ERC20(name_, symbol_) Ownable(owner_) { 
        require(owner_ != address(0), "Owner cannot be the zero address");

        // Simpan nilai desimal secara manual
        _customDecimals = decimals_;

        if (initialSupply_ > 0) {
            _mint(owner_, initialSupply_);
        }
    }

    /**
     * @dev KOREKSI: Override fungsi decimals() untuk mengembalikan nilai kustom.
     * Ini adalah cara yang benar di OpenZeppelin v5.x.
     */
    function decimals() public view virtual override returns (uint8) {
        return _customDecimals;
    }

    function mint(address to, uint256 amount_) external onlyOwner {
        _mint(to, amount_);
    }

    function burn(address from, uint256 amount_) external onlyOwner {
        _burn(from, amount_);
    }
}