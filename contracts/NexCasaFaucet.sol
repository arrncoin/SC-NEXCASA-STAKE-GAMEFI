// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract NexCasaFaucet is Ownable {
    using SafeERC20 for IERC20;

    struct TokenConfig {
        IERC20 token;
        uint256 amountPerClaim;
        uint256 cooldownSeconds;
        bool enabled;
    }

    mapping(address => TokenConfig) public configs;
    mapping(address => mapping(address => uint256)) public nextClaimAt;

    event TokenConfigured(address indexed token, uint256 amountPerClaim, uint256 cooldownSeconds, bool enabled);
    event Claimed(address indexed token, address indexed user, uint256 amount);

    /// @notice Constructor yang menerima alamat pemilik awal
    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Set konfigurasi token faucet
    function setTokenConfig(
        address tokenAddr,
        uint256 amountPerClaim,
        uint256 cooldownSeconds,
        bool enabled
    ) external onlyOwner {
        require(tokenAddr != address(0), "token 0");

        configs[tokenAddr] = TokenConfig({
            token: IERC20(tokenAddr),
            amountPerClaim: amountPerClaim,
            cooldownSeconds: cooldownSeconds,
            enabled: enabled
        });

        emit TokenConfigured(tokenAddr, amountPerClaim, cooldownSeconds, enabled);
    }

    /// @notice Claim token tertentu
    function claim(address tokenAddr) external {
        TokenConfig storage cfg = configs[tokenAddr];
        require(cfg.enabled, "token not enabled");
        require(cfg.amountPerClaim > 0, "amount 0");

        uint256 allowedAt = nextClaimAt[tokenAddr][msg.sender];
        require(block.timestamp >= allowedAt, "cooldown");

        uint256 bal = cfg.token.balanceOf(address(this));
        require(bal >= cfg.amountPerClaim, "faucet empty");

        cfg.token.safeTransfer(msg.sender, cfg.amountPerClaim);
        nextClaimAt[tokenAddr][msg.sender] = block.timestamp + cfg.cooldownSeconds;

        emit Claimed(tokenAddr, msg.sender, cfg.amountPerClaim);
    }

    /// @notice Claim beberapa token sekaligus dalam 1 transaksi
    function claimAll(address[] calldata tokenAddrs) external {
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            address tokenAddr = tokenAddrs[i];
            TokenConfig storage cfg = configs[tokenAddr];

            uint256 allowedAt = nextClaimAt[tokenAddr][msg.sender];
            uint256 bal = cfg.token.balanceOf(address(this));

            if (
                cfg.enabled &&
                cfg.amountPerClaim > 0 &&
                block.timestamp >= allowedAt &&
                bal >= cfg.amountPerClaim
            ) {
                cfg.token.safeTransfer(msg.sender, cfg.amountPerClaim);
                nextClaimAt[tokenAddr][msg.sender] = block.timestamp + cfg.cooldownSeconds;
                emit Claimed(tokenAddr, msg.sender, cfg.amountPerClaim);
            }
        }
    }

    /// @notice Withdraw token dari faucet (owner saja)
    function withdrawToken(address tokenAddr, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "to 0");
        uint256 bal = IERC20(tokenAddr).balanceOf(address(this));
        require(amount <= bal, "insufficient balance");
        IERC20(tokenAddr).safeTransfer(to, amount);
    }

    /// @notice Withdraw ETH dari faucet (owner saja)
    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "to 0");
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "ETH transfer failed");
    }

    receive() external payable {}
}
