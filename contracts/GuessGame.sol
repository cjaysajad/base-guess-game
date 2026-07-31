// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title GuessGame
/// @notice A fully on-chain number-guessing game. Players pay an entry fee
///         and guess a number in [1, range]. If correct, they win the pot
///         (entry fee * payoutMultiplier), otherwise the fee stays in the
///         contract to fund future prizes.
///
/// @dev IMPORTANT SECURITY NOTE: the "randomness" here is derived from
///      block data (prevrandao + timestamp + player + nonce). This is fine
///      for a small demo / low-stakes game, but it is NOT secure against a
///      miner/validator or a contract that can see the pending transaction
///      and react to it. For a real-money game, replace `_random()` with a
///      commit-reveal scheme or an oracle such as Chainlink VRF.
contract GuessGame is Ownable, ReentrancyGuard {
    uint256 public entryFee = 0.0005 ether;
    uint256 public range = 10; // players guess a number from 1 to `range`
    uint256 public payoutMultiplier = 8; // winner gets entryFee * payoutMultiplier

    uint256 private _nonce;

    event GuessResult(
        address indexed player,
        uint256 guess,
        uint256 result,
        bool won,
        uint256 payout
    );
    event Funded(address indexed from, uint256 amount);
    event ParamsUpdated(uint256 entryFee, uint256 range, uint256 payoutMultiplier);

    constructor(address initialOwner) Ownable(initialOwner) {}

    /// @notice Play the game by guessing a number between 1 and `range`.
    function play(uint256 guess) external payable nonReentrant {
        require(msg.value == entryFee, "Incorrect entry fee");
        require(guess >= 1 && guess <= range, "Guess out of range");


        uint256 result = _random();
        bool won = (result == guess);
        uint256 payout = 0;

        if (won) {
            payout = entryFee * payoutMultiplier;
            require(address(this).balance >= payout, "Pot too small, try later");
            (bool sent, ) = payable(msg.sender).call{value: payout}("");
            require(sent, "Payout failed");
        }

        emit GuessResult(msg.sender, guess, result, won, payout);
    }

    /// @dev Pseudo-random number in [1, range]. See security note above.
    function _random() private returns (uint256) {
        _nonce += 1;
        uint256 rand = uint256(
            keccak256(
                abi.encodePacked(
                    block.prevrandao,
                    block.timestamp,
                    msg.sender,
                    _nonce
                )
            )
        );
        return (rand % range) + 1;
    }

    /// @notice Anyone can top up the prize pool.
    function fund() external payable {
        emit Funded(msg.sender, msg.value);
    }

    function setParams(
        uint256 newEntryFee,
        uint256 newRange,
        uint256 newPayoutMultiplier
    ) external onlyOwner {
        require(newRange > 0, "Range must be > 0");
        entryFee = newEntryFee;
        range = newRange;
        payoutMultiplier = newPayoutMultiplier;
        emit ParamsUpdated(newEntryFee, newRange, newPayoutMultiplier);
    }

    /// @notice Owner can withdraw excess funds beyond what's needed for one payout,
    ///         to manage treasury without ever leaving the pot unable to pay a winner.
    function withdrawExcess(uint256 amount) external onlyOwner nonReentrant {
        uint256 reserve = entryFee * payoutMultiplier;
        require(address(this).balance >= reserve + amount, "Would underfund pot");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "Withdraw failed");
    }

    receive() external payable {
        emit Funded(msg.sender, msg.value);
    }
}
