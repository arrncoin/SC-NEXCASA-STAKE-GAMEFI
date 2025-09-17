// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenFaucet is Ownable {
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

    constructor(address initialOwner) Ownable(initialOwner) {}

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

    function claim(address tokenAddr) public {
        TokenConfig memory cfg = configs[tokenAddr];
        require(cfg.enabled, "token not enabled");
        require(cfg.amountPerClaim > 0, "amount 0");

        uint256 allowedAt = nextClaimAt[tokenAddr][msg.sender];
        require(block.timestamp >= allowedAt, "cooldown");

        uint256 bal = cfg.token.balanceOf(address(this));
        require(bal >= cfg.amountPerClaim, "faucet empty");

        require(cfg.token.transfer(msg.sender, cfg.amountPerClaim), "transfer failed");

        nextClaimAt[tokenAddr][msg.sender] = block.timestamp + cfg.cooldownSeconds;
        emit Claimed(tokenAddr, msg.sender, cfg.amountPerClaim);
    }

    /// @notice Claim beberapa token sekaligus dalam 1 transaksi
    function claimAll(address[] calldata tokenAddrs) external {
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            address tokenAddr = tokenAddrs[i];
            TokenConfig memory cfg = configs[tokenAddr];

            if (
                cfg.enabled &&
                cfg.amountPerClaim > 0 &&
                block.timestamp >= nextClaimAt[tokenAddr][msg.sender]
            ) {
                uint256 bal = cfg.token.balanceOf(address(this));
                if (bal >= cfg.amountPerClaim) {
                    require(cfg.token.transfer(msg.sender, cfg.amountPerClaim), "transfer failed");
                    nextClaimAt[tokenAddr][msg.sender] = block.timestamp + cfg.cooldownSeconds;
                    emit Claimed(tokenAddr, msg.sender, cfg.amountPerClaim);
                }
            }
        }
    }

    function withdrawToken(address tokenAddr, address to, uint256 amount) external onlyOwner {
        require(to != address(0), "to 0");
        IERC20(tokenAddr).transfer(to, amount);
    }

    function withdrawETH(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "to 0");
        to.transfer(amount);
    }

    receive() external payable {}
}
